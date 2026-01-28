import { NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { prisma } from '@/lib/prisma'
import { authOptions } from '@/lib/auth'
import { diarySchema } from '@/lib/validations'
import { ZodError } from 'zod'

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const session = await getServerSession(authOptions)

    if (!session?.user?.id) {
      return NextResponse.json(
        { message: 'Unauthorized' },
        { status: 401 }
      )
    }

    const diary = await prisma.diary.findFirst({
      where: {
        id,
        userId: session.user.id,
      },
    })

    if (!diary) {
      return NextResponse.json(
        { message: 'Diary entry not found' },
        { status: 404 }
      )
    }

    return NextResponse.json(diary)
  } catch (error) {
    console.error('Get diary error:', error)
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function PUT(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const session = await getServerSession(authOptions)

    if (!session?.user?.id) {
      return NextResponse.json(
        { message: 'Unauthorized' },
        { status: 401 }
      )
    }

    const existingDiary = await prisma.diary.findFirst({
      where: {
        id,
        userId: session.user.id,
      },
    })

    if (!existingDiary) {
      return NextResponse.json(
        { message: 'Diary entry not found' },
        { status: 404 }
      )
    }

    const body = await req.json()
    const validatedData = diarySchema.parse(body)

    const diary = await prisma.diary.update({
      where: { id },
      data: {
        title: validatedData.title,
        content: validatedData.content,
        entryDate: new Date(validatedData.entryDate),
      },
    })

    return NextResponse.json(diary)
  } catch (error) {
    if (error instanceof ZodError) {
      const errors: Record<string, string> = {}
      error.errors.forEach((err) => {
        if (err.path[0]) {
          errors[err.path[0] as string] = err.message
        }
      })
      return NextResponse.json({ errors }, { status: 400 })
    }

    console.error('Update diary error:', error)
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const session = await getServerSession(authOptions)

    if (!session?.user?.id) {
      return NextResponse.json(
        { message: 'Unauthorized' },
        { status: 401 }
      )
    }

    const existingDiary = await prisma.diary.findFirst({
      where: {
        id,
        userId: session.user.id,
      },
    })

    if (!existingDiary) {
      return NextResponse.json(
        { message: 'Diary entry not found' },
        { status: 404 }
      )
    }

    await prisma.diary.delete({
      where: { id },
    })

    return NextResponse.json({ message: 'Diary entry deleted' })
  } catch (error) {
    console.error('Delete diary error:', error)
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    )
  }
}
