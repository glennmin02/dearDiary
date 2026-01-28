import { getServerSession } from 'next-auth'
import { notFound } from 'next/navigation'
import Link from 'next/link'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { DeleteButton } from '@/components/diary/DeleteButton'
import { PrintButton } from '@/components/diary/PrintButton'

interface DiaryPageProps {
  params: Promise<{ id: string }>
}

export default async function DiaryPage({ params }: DiaryPageProps) {
  const { id } = await params
  const session = await getServerSession(authOptions)

  const diary = await prisma.diary.findFirst({
    where: {
      id,
      userId: session!.user.id,
    },
  })

  if (!diary) {
    notFound()
  }

  const formatDate = (date: Date) => {
    return new Date(date).toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  const formatDateTime = (date: Date) => {
    return new Date(date).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    })
  }

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8">
      {/* Back Button */}
      <Link
        href="/dashboard"
        className="inline-flex items-center gap-2 text-sm text-ink-500 hover:text-ink-700 mb-6 no-print"
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
        </svg>
        Back to Dashboard
      </Link>

      <article className="animate-in">
        {/* Header */}
        <header className="mb-8">
          <span className="inline-block text-sm font-medium text-diary-600 bg-diary-100 px-3 py-1 rounded-full mb-4">
            {formatDate(diary.entryDate)}
          </span>
          <h1 className="font-serif text-3xl md:text-4xl text-ink-900 mb-4 leading-tight">
            {diary.title}
          </h1>
          <div className="flex flex-wrap gap-4 text-sm text-ink-400">
            <span>Created: {formatDateTime(diary.createdAt)}</span>
            {diary.updatedAt.getTime() !== diary.createdAt.getTime() && (
              <span>Updated: {formatDateTime(diary.updatedAt)}</span>
            )}
          </div>
        </header>

        {/* Content */}
        <div className="prose prose-ink max-w-none mb-8">
          <div className="whitespace-pre-wrap text-ink-700 leading-relaxed">
            {diary.content}
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-3 pt-6 border-t border-ink-100 no-print">
          <Link href={`/diary/${diary.id}/edit`} className="btn-secondary">
            <svg className="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            Edit
          </Link>
          <PrintButton />
          <DeleteButton diaryId={diary.id} />
        </div>
      </article>
    </div>
  )
}
