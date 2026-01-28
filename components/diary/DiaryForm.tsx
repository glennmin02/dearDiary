'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'

interface Diary {
  id: string
  title: string
  content: string
  entryDate: Date
}

interface DiaryFormProps {
  diary?: Diary
}

export function DiaryForm({ diary }: DiaryFormProps) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const [title, setTitle] = useState(diary?.title || '')
  const [content, setContent] = useState(diary?.content || '')
  const [entryDate, setEntryDate] = useState(
    diary
      ? new Date(diary.entryDate).toISOString().split('T')[0]
      : new Date().toISOString().split('T')[0]
  )

  const wordCount = content
    .trim()
    .split(/\s+/)
    .filter((word) => word.length > 0).length

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setErrors({})
    setLoading(true)

    const data = { title, content, entryDate }

    try {
      const res = await fetch(
        diary ? `/api/diaries/${diary.id}` : '/api/diaries',
        {
          method: diary ? 'PUT' : 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        }
      )

      const result = await res.json()

      if (!res.ok) {
        if (result.errors) {
          setErrors(result.errors)
        } else {
          setErrors({ form: result.message || 'Something went wrong' })
        }
        setLoading(false)
        return
      }

      router.push(diary ? `/diary/${diary.id}` : '/dashboard')
      router.refresh()
    } catch (error) {
      setErrors({ form: 'Something went wrong' })
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="card animate-in stagger-1">
      {errors.form && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
          {errors.form}
        </div>
      )}

      <div className="space-y-6">
        {/* Date */}
        <div>
          <label htmlFor="entryDate" className="label">
            Date
          </label>
          <input
            id="entryDate"
            type="date"
            value={entryDate}
            onChange={(e) => setEntryDate(e.target.value)}
            required
            className={`input max-w-xs ${errors.entryDate ? 'input-error' : ''}`}
          />
          {errors.entryDate && (
            <p className="mt-1.5 text-sm text-red-600">{errors.entryDate}</p>
          )}
        </div>

        {/* Title */}
        <div>
          <div className="flex items-center justify-between mb-1.5">
            <label htmlFor="title" className="label mb-0">
              Title
            </label>
            <span className="text-xs text-ink-400">{title.length}/200</span>
          </div>
          <input
            id="title"
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            maxLength={200}
            className={`input ${errors.title ? 'input-error' : ''}`}
            placeholder="Give your entry a title..."
          />
          {errors.title && (
            <p className="mt-1.5 text-sm text-red-600">{errors.title}</p>
          )}
        </div>

        {/* Content */}
        <div>
          <div className="flex items-center justify-between mb-1.5">
            <label htmlFor="content" className="label mb-0">
              Content
            </label>
            <span className="text-xs text-ink-400">
              {content.length}/10,000 chars | {wordCount} words
            </span>
          </div>
          <textarea
            id="content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
            maxLength={10000}
            rows={15}
            className={`input resize-none ${errors.content ? 'input-error' : ''}`}
            placeholder="What's on your mind today..."
          />
          {errors.content && (
            <p className="mt-1.5 text-sm text-red-600">{errors.content}</p>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-3 mt-8 pt-6 border-t border-ink-100">
        <button type="submit" disabled={loading} className="btn-primary">
          {loading ? (
            <span className="flex items-center gap-2">
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                  fill="none"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              Saving...
            </span>
          ) : diary ? (
            'Update Entry'
          ) : (
            'Save Entry'
          )}
        </button>
        <Link href={diary ? `/diary/${diary.id}` : '/dashboard'} className="btn-secondary">
          Cancel
        </Link>
      </div>
    </form>
  )
}
