import Link from 'next/link'
import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'

export default async function Home() {
  const session = await getServerSession(authOptions)

  if (session) {
    redirect('/dashboard')
  }

  return (
    <main className="min-h-screen flex flex-col">
      {/* Hero Section */}
      <div className="flex-1 flex items-center justify-center px-4 py-16">
        <div className="max-w-2xl mx-auto text-center">
          <div className="mb-8 animate-in">
            <span className="inline-block px-4 py-1.5 bg-diary-100 text-diary-700 rounded-full text-sm font-medium mb-6">
              Your Personal Space
            </span>
            <h1 className="font-serif text-5xl md:text-6xl lg:text-7xl text-ink-900 mb-6 leading-tight">
              Dear Diary...
            </h1>
            <p className="text-lg md:text-xl text-ink-500 max-w-lg mx-auto leading-relaxed">
              Capture your thoughts, preserve your memories, and reflect on your journey.
              A beautiful, private space for your daily reflections.
            </p>
          </div>

          <div className="flex flex-col sm:flex-row gap-4 justify-center animate-in stagger-1">
            <Link
              href="/register"
              className="btn-primary px-8 py-3 text-base"
            >
              Start Writing
            </Link>
            <Link
              href="/login"
              className="btn-secondary px-8 py-3 text-base"
            >
              Sign In
            </Link>
          </div>

          {/* Features */}
          <div className="mt-20 grid sm:grid-cols-3 gap-8 text-left animate-in stagger-2">
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-lg bg-diary-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-diary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="font-semibold text-ink-900">Private & Secure</h3>
              <p className="text-sm text-ink-500">Your entries are encrypted and only accessible by you.</p>
            </div>
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-lg bg-diary-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-diary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
              <h3 className="font-semibold text-ink-900">Easy to Search</h3>
              <p className="text-sm text-ink-500">Find any memory instantly with powerful search.</p>
            </div>
            <div className="space-y-3">
              <div className="w-10 h-10 rounded-lg bg-diary-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-diary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <h3 className="font-semibold text-ink-900">Beautiful Design</h3>
              <p className="text-sm text-ink-500">A calm, distraction-free writing experience.</p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="py-6 text-center text-sm text-ink-400">
        <p>&copy; {new Date().getFullYear()} Dear Diary. All rights reserved.</p>
      </footer>
    </main>
  )
}
