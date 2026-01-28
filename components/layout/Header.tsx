'use client'

import { useState } from 'react'
import Link from 'next/link'
import { signOut } from 'next-auth/react'
import { usePathname } from 'next/navigation'

interface HeaderProps {
  username: string
}

export function Header({ username }: HeaderProps) {
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const pathname = usePathname()

  return (
    <header className="sticky top-0 z-50 bg-diary-50/80 backdrop-blur-lg border-b border-ink-100 no-print">
      <div className="max-w-6xl mx-auto px-4 sm:px-6">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link
            href="/dashboard"
            className="font-serif text-xl text-ink-900 hover:text-ink-700 transition-colors"
          >
            Dear Diary
          </Link>

          {/* Navigation */}
          <nav className="flex items-center gap-1">
            <Link
              href="/dashboard"
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                pathname === '/dashboard'
                  ? 'bg-ink-100 text-ink-900'
                  : 'text-ink-600 hover:bg-ink-50 hover:text-ink-900'
              }`}
            >
              Dashboard
            </Link>
            <Link
              href="/diary/new"
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                pathname === '/diary/new'
                  ? 'bg-ink-100 text-ink-900'
                  : 'text-ink-600 hover:bg-ink-50 hover:text-ink-900'
              }`}
            >
              New Entry
            </Link>

            {/* User Dropdown */}
            <div className="relative ml-2">
              <button
                onClick={() => setDropdownOpen(!dropdownOpen)}
                className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium text-ink-600 hover:bg-ink-50 hover:text-ink-900 transition-colors"
              >
                <div className="w-7 h-7 rounded-full bg-diary-200 flex items-center justify-center text-diary-700 font-semibold">
                  {username[0].toUpperCase()}
                </div>
                <span className="hidden sm:inline">{username}</span>
                <svg
                  className={`w-4 h-4 transition-transform ${dropdownOpen ? 'rotate-180' : ''}`}
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {dropdownOpen && (
                <>
                  <div
                    className="fixed inset-0 z-10"
                    onClick={() => setDropdownOpen(false)}
                  />
                  <div className="absolute right-0 mt-2 w-48 py-1 bg-white rounded-xl shadow-card border border-ink-100 z-20">
                    <div className="px-4 py-2 border-b border-ink-100">
                      <p className="text-sm font-medium text-ink-900">{username}</p>
                    </div>
                    <Link
                      href="/settings"
                      onClick={() => setDropdownOpen(false)}
                      className="block px-4 py-2 text-sm text-ink-600 hover:bg-ink-50 hover:text-ink-900"
                    >
                      Settings
                    </Link>
                    <button
                      onClick={() => signOut({ callbackUrl: '/' })}
                      className="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                    >
                      Sign Out
                    </button>
                  </div>
                </>
              )}
            </div>
          </nav>
        </div>
      </div>
    </header>
  )
}
