import { getServerSession } from 'next-auth'
import { notFound } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { DiaryForm } from '@/components/diary/DiaryForm'

interface EditDiaryPageProps {
  params: Promise<{ id: string }>
}

export default async function EditDiaryPage({ params }: EditDiaryPageProps) {
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

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8">
      <div className="mb-8 animate-in">
        <h1 className="text-2xl font-semibold text-ink-900 mb-2">Edit Entry</h1>
        <p className="text-ink-500">Update your diary entry</p>
      </div>

      <DiaryForm diary={diary} />
    </div>
  )
}
