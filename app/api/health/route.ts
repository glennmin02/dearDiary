import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

// Health check endpoint - also keeps database warm
// Add to vercel.json: { "crons": [{ "path": "/api/health", "schedule": "*/4 * * * *" }] }
export async function GET() {
  try {
    // Simple query to keep connection alive
    await prisma.$queryRaw`SELECT 1`

    return NextResponse.json({
      status: 'healthy',
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    return NextResponse.json(
      { status: 'unhealthy', error: 'Database connection failed' },
      { status: 503 }
    )
  }
}
