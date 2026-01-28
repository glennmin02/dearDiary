import { Suspense } from 'react'
import { getServerSession } from 'next-auth'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { DiaryList } from '@/components/diary/DiaryList'

interface DashboardPageProps {
  searchParams: Promise<{ page?: string; search?: string }>
}

export default async function DashboardPage({ searchParams }: DashboardPageProps) {
  const resolvedSearchParams = await searchParams
  const session = await getServerSession(authOptions)
  const page = parseInt(resolvedSearchParams.page || '1')
  const search = resolvedSearchParams.search || ''
  const limit = 12

  const where = {
    userId: session!.user.id,
    ...(search && {
      OR: [
        { title: { contains: search, mode: 'insensitive' as const } },
        { content: { contains: search, mode: 'insensitive' as const } },
      ],
    }),
  }

  const [diaries, total] = await Promise.all([
    prisma.diary.findMany({
      where,
      orderBy: { entryDate: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
    prisma.diary.count({ where }),
  ])

  const totalPages = Math.ceil(total / limit)

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8">
      {/* Header */}
      <div className="mb-8 animate-in">
        <h1 className="text-2xl font-semibold text-ink-900 mb-2">
          Welcome back, {session!.user.username}
        </h1>
        <p className="text-ink-500">
          {total === 0
            ? "You haven't written any entries yet. Start capturing your thoughts!"
            : `You have ${total} ${total === 1 ? 'entry' : 'entries'} in your diary.`}
        </p>
      </div>

      <Suspense fallback={<div className="text-center py-8 text-ink-500">Loading...</div>}>
        <DiaryList
          initialDiaries={diaries}
          initialSearch={search}
          initialPage={page}
          totalPages={totalPages}
          total={total}
        />
      </Suspense>
    </div>
  )
}
