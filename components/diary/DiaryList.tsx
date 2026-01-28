'use client'

import { useState } from 'react'
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

interface DiaryListProps {
  initialDiaries: Diary[]
  initialSearch: string
  initialPage: number
  totalPages: number
  total: number
}

export function DiaryList({
  initialDiaries,
  initialSearch,
  initialPage,
  totalPages,
  total,
}: DiaryListProps) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [search, setSearch] = useState(initialSearch)

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    const params = new URLSearchParams(searchParams.toString())
    if (search) {
      params.set('search', search)
    } else {
      params.delete('search')
    }
    params.delete('page')
    router.push(`/dashboard?${params.toString()}`)
  }

  const clearSearch = () => {
    setSearch('')
    router.push('/dashboard')
  }

  return (
    <>
      {/* Search Bar */}
      <form onSubmit={handleSearch} className="mb-8 animate-in stagger-1">
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

      {/* Diary Grid */}
      {initialDiaries.length === 0 ? (
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
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 animate-in stagger-2">
            {initialDiaries.map((diary) => (
              <DiaryCard key={diary.id} diary={diary} />
            ))}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-2 mt-8 animate-in stagger-3">
              <Link
                href={`/dashboard?page=${initialPage - 1}${initialSearch ? `&search=${initialSearch}` : ''}`}
                className={`btn-secondary ${initialPage <= 1 ? 'opacity-50 pointer-events-none' : ''}`}
              >
                <svg className="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
                Previous
              </Link>
              <span className="px-4 py-2 text-sm text-ink-600">
                Page {initialPage} of {totalPages}
              </span>
              <Link
                href={`/dashboard?page=${initialPage + 1}${initialSearch ? `&search=${initialSearch}` : ''}`}
                className={`btn-secondary ${initialPage >= totalPages ? 'opacity-50 pointer-events-none' : ''}`}
              >
                Next
                <svg className="w-4 h-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </Link>
            </div>
          )}
        </>
      )}
    </>
  )
}
