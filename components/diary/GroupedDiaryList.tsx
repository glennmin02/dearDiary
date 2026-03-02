'use client'

import { useState, useMemo } from 'react'
import Link from 'next/link'
import { useRouter, useSearchParams } from 'next/navigation'
import { DiaryCard } from './DiaryCard'

interface Diary {
  id: string
  title: string
  content: string
  entryDate: Date
  createdAt: Date
  updatedAt: Date
}

interface GroupedDiaryListProps {
  diaries: Diary[]
  initialSearch: string
  total: number
}

interface MonthGroup {
  month: number
  monthName: string
  diaries: Diary[]
}

interface YearGroup {
  year: number
  months: MonthGroup[]
  totalEntries: number
}

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
]

export function GroupedDiaryList({
  diaries,
  initialSearch,
  total,
}: GroupedDiaryListProps) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [search, setSearch] = useState(initialSearch)

  // Get current year and month for default expansion
  const now = new Date()
  const currentYear = now.getFullYear()
  const currentMonth = now.getMonth()

  // Track expanded state for years and months
  const [expandedYears, setExpandedYears] = useState<Set<number>>(() => new Set([currentYear]))
  const [expandedMonths, setExpandedMonths] = useState<Set<string>>(() => new Set([`${currentYear}-${currentMonth}`]))

  // Group diaries by year and month
  const groupedDiaries = useMemo(() => {
    const groups: Map<number, Map<number, Diary[]>> = new Map()

    diaries.forEach((diary) => {
      const date = new Date(diary.entryDate)
      const year = date.getUTCFullYear()
      const month = date.getUTCMonth()

      if (!groups.has(year)) {
        groups.set(year, new Map())
      }
      const yearGroup = groups.get(year)!
      if (!yearGroup.has(month)) {
        yearGroup.set(month, [])
      }
      yearGroup.get(month)!.push(diary)
    })

    // Convert to sorted array structure
    const result: YearGroup[] = []
    const sortedYears = Array.from(groups.keys()).sort((a, b) => b - a)

    sortedYears.forEach((year) => {
      const monthsMap = groups.get(year)!
      const sortedMonths = Array.from(monthsMap.keys()).sort((a, b) => b - a)

      const months: MonthGroup[] = sortedMonths.map((month) => ({
        month,
        monthName: MONTH_NAMES[month],
        diaries: monthsMap.get(month)!.sort(
          (a, b) => new Date(b.entryDate).getTime() - new Date(a.entryDate).getTime()
        ),
      }))

      result.push({
        year,
        months,
        totalEntries: months.reduce((sum, m) => sum + m.diaries.length, 0),
      })
    })

    return result
  }, [diaries])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    const params = new URLSearchParams(searchParams.toString())
    if (search) {
      params.set('search', search)
    } else {
      params.delete('search')
    }
    router.push(`/dashboard?${params.toString()}`)
  }

  const clearSearch = () => {
    setSearch('')
    router.push('/dashboard')
  }

  const toggleYear = (year: number) => {
    setExpandedYears((prev) => {
      const next = new Set(prev)
      if (next.has(year)) {
        next.delete(year)
      } else {
        next.add(year)
      }
      return next
    })
  }

  const toggleMonth = (year: number, month: number) => {
    const key = `${year}-${month}`
    setExpandedMonths((prev) => {
      const next = new Set(prev)
      if (next.has(key)) {
        next.delete(key)
      } else {
        next.add(key)
      }
      return next
    })
  }

  const expandAll = () => {
    const allYears = new Set(groupedDiaries.map((g) => g.year))
    const allMonths = new Set<string>()
    groupedDiaries.forEach((yg) => {
      yg.months.forEach((mg) => {
        allMonths.add(`${yg.year}-${mg.month}`)
      })
    })
    setExpandedYears(allYears)
    setExpandedMonths(allMonths)
  }

  const collapseAll = () => {
    setExpandedYears(new Set())
    setExpandedMonths(new Set())
  }

  return (
    <>
      {/* Search Bar */}
      <form onSubmit={handleSearch} className="mb-6 animate-in stagger-1">
        <div className="flex gap-3">
          <div className="flex-1 relative">
            <svg
              className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-ink-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search your entries..."
              className="input pl-12"
            />
          </div>
          <button type="submit" className="btn-primary">
            Search
          </button>
          {initialSearch && (
            <button type="button" onClick={clearSearch} className="btn-secondary">
              Clear
            </button>
          )}
        </div>
        {initialSearch && (
          <p className="mt-3 text-sm text-ink-500">
            Showing results for &quot;{initialSearch}&quot; ({total} {total === 1 ? 'entry' : 'entries'} found)
          </p>
        )}
      </form>

      {/* Empty State */}
      {diaries.length === 0 ? (
        <div className="text-center py-16 animate-in stagger-2">
          <div className="w-16 h-16 rounded-full bg-diary-100 flex items-center justify-center mx-auto mb-4">
            <svg
              className="w-8 h-8 text-diary-500"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
              />
            </svg>
          </div>
          <h3 className="text-lg font-semibold text-ink-900 mb-2">
            {initialSearch ? 'No entries found' : 'No entries yet'}
          </h3>
          <p className="text-ink-500 mb-6">
            {initialSearch
              ? 'Try a different search term'
              : 'Start writing your first diary entry'}
          </p>
          {!initialSearch && (
            <Link href="/diary/new" className="btn-primary">
              Write Your First Entry
            </Link>
          )}
        </div>
      ) : (
        <>
          {/* Expand/Collapse Controls */}
          <div className="flex justify-end gap-2 mb-4 animate-in stagger-2">
            <button
              onClick={expandAll}
              className="text-sm text-ink-500 hover:text-ink-700 transition-colors"
            >
              Expand All
            </button>
            <span className="text-ink-300">|</span>
            <button
              onClick={collapseAll}
              className="text-sm text-ink-500 hover:text-ink-700 transition-colors"
            >
              Collapse All
            </button>
          </div>

          {/* Grouped Diary List */}
          <div className="space-y-4 animate-in stagger-2">
            {groupedDiaries.map((yearGroup) => (
              <div key={yearGroup.year} className="border border-ink-200 rounded-xl overflow-hidden">
                {/* Year Header */}
                <button
                  onClick={() => toggleYear(yearGroup.year)}
                  className="w-full flex items-center justify-between px-5 py-4 bg-ink-50 hover:bg-ink-100 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <svg
                      className={`w-5 h-5 text-ink-400 transition-transform duration-200 ${
                        expandedYears.has(yearGroup.year) ? 'rotate-90' : ''
                      }`}
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                    <span className="text-lg font-semibold text-ink-900">{yearGroup.year}</span>
                  </div>
                  <span className="text-sm font-medium text-ink-500 bg-ink-200 px-3 py-1 rounded-full">
                    {yearGroup.totalEntries} {yearGroup.totalEntries === 1 ? 'entry' : 'entries'}
                  </span>
                </button>

                {/* Months */}
                {expandedYears.has(yearGroup.year) && (
                  <div className="divide-y divide-ink-100">
                    {yearGroup.months.map((monthGroup) => {
                      const monthKey = `${yearGroup.year}-${monthGroup.month}`
                      const isExpanded = expandedMonths.has(monthKey)

                      return (
                        <div key={monthKey}>
                          {/* Month Header */}
                          <button
                            onClick={() => toggleMonth(yearGroup.year, monthGroup.month)}
                            className="w-full flex items-center justify-between px-5 py-3 bg-white hover:bg-diary-50 transition-colors"
                          >
                            <div className="flex items-center gap-3">
                              <svg
                                className={`w-4 h-4 text-diary-500 transition-transform duration-200 ${
                                  isExpanded ? 'rotate-90' : ''
                                }`}
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                              >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                              </svg>
                              <span className="font-medium text-ink-800">{monthGroup.monthName}</span>
                            </div>
                            <span className="text-xs font-medium text-diary-600 bg-diary-100 px-2.5 py-1 rounded-full">
                              {monthGroup.diaries.length} {monthGroup.diaries.length === 1 ? 'entry' : 'entries'}
                            </span>
                          </button>

                          {/* Diary Cards */}
                          {isExpanded && (
                            <div className="p-4 bg-diary-50/30">
                              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                                {monthGroup.diaries.map((diary) => (
                                  <DiaryCard key={diary.id} diary={diary} />
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      )
                    })}
                  </div>
                )}
              </div>
            ))}
          </div>
        </>
      )}
    </>
  )
}
