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
    <main className="min-h-screen flex flex-col bg-gradient-to-b from-diary-50 to-white">
      {/* Header */}
      <header className="w-full py-4 px-6">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div className="font-serif text-2xl text-diary-700">Dear Diary</div>
          <nav className="flex items-center gap-4">
            <Link href="/login" className="text-sm text-ink-600 hover:text-ink-900 transition-colors">
              Sign In
            </Link>
            <Link href="/register" className="btn-primary px-4 py-2 text-sm">
              Get Started
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <div className="flex-1 flex items-center justify-center px-4 py-16">
        <div className="max-w-3xl mx-auto text-center">
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
              Start Writing Free
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
            <div className="card p-6 space-y-3">
              <div className="w-10 h-10 rounded-lg bg-diary-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-diary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="font-semibold text-ink-900">Private & Secure</h3>
              <p className="text-sm text-ink-500">Your entries are encrypted and only accessible by you. We never sell your data.</p>
            </div>
            <div className="card p-6 space-y-3">
              <div className="w-10 h-10 rounded-lg bg-diary-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-diary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
              <h3 className="font-semibold text-ink-900">Easy to Search</h3>
              <p className="text-sm text-ink-500">Find any memory instantly with powerful search across all your entries.</p>
            </div>
            <div className="card p-6 space-y-3">
              <div className="w-10 h-10 rounded-lg bg-diary-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-diary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <h3 className="font-semibold text-ink-900">Beautiful Design</h3>
              <p className="text-sm text-ink-500">A calm, distraction-free writing experience that feels like home.</p>
            </div>
          </div>
        </div>
      </div>

      {/* How It Works Section */}
      <section className="py-16 px-4 bg-white">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="font-serif text-3xl md:text-4xl text-ink-900 mb-12">How It Works</h2>
          <div className="grid sm:grid-cols-3 gap-8">
            <div className="space-y-4">
              <div className="w-12 h-12 rounded-full bg-diary-100 text-diary-700 font-semibold text-lg flex items-center justify-center mx-auto">1</div>
              <h3 className="font-semibold text-ink-900">Create an Account</h3>
              <p className="text-sm text-ink-500">Sign up in seconds with just a username and password.</p>
            </div>
            <div className="space-y-4">
              <div className="w-12 h-12 rounded-full bg-diary-100 text-diary-700 font-semibold text-lg flex items-center justify-center mx-auto">2</div>
              <h3 className="font-semibold text-ink-900">Write Your Thoughts</h3>
              <p className="text-sm text-ink-500">Capture your daily moments, feelings, and memories.</p>
            </div>
            <div className="space-y-4">
              <div className="w-12 h-12 rounded-full bg-diary-100 text-diary-700 font-semibold text-lg flex items-center justify-center mx-auto">3</div>
              <h3 className="font-semibold text-ink-900">Reflect & Grow</h3>
              <p className="text-sm text-ink-500">Look back on your journey anytime, from any device.</p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-16 px-4 bg-diary-50">
        <div className="max-w-2xl mx-auto text-center">
          <h2 className="font-serif text-3xl md:text-4xl text-ink-900 mb-4">Start Your Journey Today</h2>
          <p className="text-ink-500 mb-8">Join thousands of people who trust Dear Diary with their personal reflections.</p>
          <Link href="/register" className="btn-primary px-8 py-3 text-base">
            Create Your Free Diary
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-8 px-4 bg-white border-t border-diary-100">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="flex flex-col items-center md:items-start gap-2">
              <div className="font-serif text-xl text-diary-700">Dear Diary</div>
              <p className="text-sm text-ink-400">Your private space for daily reflections.</p>
            </div>

            <nav className="flex flex-wrap items-center justify-center gap-6 text-sm">
              <Link href="/privacy-policy.html" className="text-ink-500 hover:text-ink-900 transition-colors">
                Privacy Policy
              </Link>
              <Link href="/terms.html" className="text-ink-500 hover:text-ink-900 transition-colors">
                Terms of Service
              </Link>
              <a href="mailto:minglenn@outlook.com" className="text-ink-500 hover:text-ink-900 transition-colors">
                Contact
              </a>
            </nav>
          </div>

          <div className="mt-8 pt-6 border-t border-diary-100 text-center">
            <p className="text-sm text-ink-400">
              &copy; {new Date().getFullYear()} Dear Diary. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </main>
  )
}
