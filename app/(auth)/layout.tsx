import Link from 'next/link'

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-4 py-12">
      <Link href="/" className="font-serif text-3xl text-ink-900 mb-8 hover:text-ink-700 transition-colors">
        Dear Diary
      </Link>
      {children}
    </div>
  )
}
