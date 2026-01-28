import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-4 py-12">
      <div className="text-center">
        <span className="text-6xl font-serif text-diary-300 mb-4 block">404</span>
        <h1 className="text-2xl font-semibold text-ink-900 mb-2">Page not found</h1>
        <p className="text-ink-500 mb-6">
          The page you&apos;re looking for doesn&apos;t exist or has been moved.
        </p>
        <Link href="/" className="btn-primary">
          Go Home
        </Link>
      </div>
    </div>
  )
}
