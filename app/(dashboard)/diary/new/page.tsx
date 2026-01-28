import { DiaryForm } from '@/components/diary/DiaryForm'

export default function NewDiaryPage() {
  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 py-8">
      <div className="mb-8 animate-in">
        <h1 className="text-2xl font-semibold text-ink-900 mb-2">New Entry</h1>
        <p className="text-ink-500">Capture your thoughts and memories</p>
      </div>

      <DiaryForm />
    </div>
  )
}
