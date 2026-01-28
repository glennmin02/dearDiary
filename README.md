# Dear Diary

A beautiful, modern personal diary application built with Next.js 14, designed for deployment on Vercel.

## Features

- User authentication (register, login, password reset)
- Create, read, update, and delete diary entries
- Full-text search across titles and content
- Pagination for large collections
- Print-friendly diary view
- Responsive design with modern UI
- Dark mode ready

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: NextAuth.js
- **Styling**: Tailwind CSS
- **Validation**: Zod

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL database (local or cloud)

### Local Development

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd dailyDiary
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   ```

   Update `.env` with your database URL and NextAuth secret:
   ```
   DATABASE_URL="postgresql://user:password@localhost:5432/dailydiary"
   NEXTAUTH_URL="http://localhost:3000"
   NEXTAUTH_SECRET="generate-with: openssl rand -base64 32"
   ```

4. Push the database schema:
   ```bash
   npm run db:push
   ```

5. Start the development server:
   ```bash
   npm run dev
   ```

6. Open [http://localhost:3000](http://localhost:3000)

## Deploying to Vercel

### Option 1: Vercel Postgres (Recommended)

1. Push your code to GitHub

2. Import the project in [Vercel](https://vercel.com/new)

3. Add Vercel Postgres from the Storage tab:
   - Go to your project dashboard
   - Click "Storage" tab
   - Click "Create Database" and select "Postgres"
   - Connect to your project

4. Add the `NEXTAUTH_SECRET` environment variable:
   ```
   NEXTAUTH_SECRET=your-generated-secret
   ```
   Generate with: `openssl rand -base64 32`

5. Deploy! Vercel will automatically:
   - Set `DATABASE_URL` from Vercel Postgres
   - Run `prisma generate` during build
   - Deploy your application

### Option 2: External PostgreSQL

You can also use external PostgreSQL providers:
- [Neon](https://neon.tech) (serverless, free tier)
- [Supabase](https://supabase.com) (free tier)
- [PlanetScale](https://planetscale.com) (MySQL - would need schema changes)

Set the `DATABASE_URL` environment variable in Vercel with your connection string.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `NEXTAUTH_URL` | Your app URL (auto-set by Vercel in production) |
| `NEXTAUTH_SECRET` | Secret for JWT encryption (required) |

## Project Structure

```
├── app/
│   ├── (auth)/           # Auth pages (login, register)
│   ├── (dashboard)/      # Protected pages
│   │   ├── dashboard/    # Main diary list
│   │   ├── diary/        # Diary CRUD pages
│   │   └── settings/     # User settings
│   ├── api/              # API routes
│   └── layout.tsx        # Root layout
├── components/
│   ├── diary/            # Diary components
│   ├── layout/           # Layout components
│   └── providers/        # Context providers
├── lib/
│   ├── auth.ts           # NextAuth config
│   ├── prisma.ts         # Prisma client
│   └── validations.ts    # Zod schemas
├── prisma/
│   └── schema.prisma     # Database schema
└── types/
    └── next-auth.d.ts    # Type definitions
```

## License

MIT
