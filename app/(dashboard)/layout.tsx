import { getServerSession } from 'next-auth'
import { redirect } from 'next/navigation'
import { authOptions } from '@/lib/auth'
import { Header } from '@/components/layout/Header'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const session = await getServerSession(authOptions)

  if (!session) {
    redirect('/login')
  }

  return (
    <div className="min-h-screen flex flex-col">
      <Header username={session.user.username} />
      <main className="flex-1">{children}</main>
      <footer className="py-6 text-center text-sm text-ink-400 no-print">
        <p>&copy; {new Date().getFullYear()} Dear Diary</p>
      </footer>
    </div>
  )
}
