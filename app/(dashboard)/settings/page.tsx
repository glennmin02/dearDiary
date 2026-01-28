'use client'

import { useState } from 'react'
import { signOut } from 'next-auth/react'

export default function SettingsPage() {
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [success, setSuccess] = useState(false)

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setErrors({})
    setSuccess(false)
    setLoading(true)

    const formData = new FormData(e.currentTarget)
    const data = {
      currentPassword: formData.get('currentPassword') as string,
      newPassword: formData.get('newPassword') as string,
      confirmPassword: formData.get('confirmPassword') as string,
    }

    const res = await fetch('/api/auth/reset-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })

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

    setSuccess(true)
    setLoading(false)
    ;(e.target as HTMLFormElement).reset()
  }

  return (
    <div className="max-w-xl mx-auto px-4 sm:px-6 py-8">
      <div className="mb-8 animate-in">
        <h1 className="text-2xl font-semibold text-ink-900 mb-2">Settings</h1>
        <p className="text-ink-500">Manage your account settings</p>
      </div>

      {/* Change Password */}
      <div className="card animate-in stagger-1">
        <h2 className="text-lg font-semibold text-ink-900 mb-6">Change Password</h2>

        {errors.form && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            {errors.form}
          </div>
        )}

        {success && (
          <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700 text-sm">
            Password updated successfully!
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label htmlFor="currentPassword" className="label">
              Current Password
            </label>
            <input
              id="currentPassword"
              name="currentPassword"
              type="password"
              required
              className={`input ${errors.currentPassword ? 'input-error' : ''}`}
              placeholder="Enter current password"
            />
            {errors.currentPassword && (
              <p className="mt-1.5 text-sm text-red-600">{errors.currentPassword}</p>
            )}
          </div>

          <div>
            <label htmlFor="newPassword" className="label">
              New Password
            </label>
            <input
              id="newPassword"
              name="newPassword"
              type="password"
              required
              className={`input ${errors.newPassword ? 'input-error' : ''}`}
              placeholder="Enter new password"
            />
            {errors.newPassword && (
              <p className="mt-1.5 text-sm text-red-600">{errors.newPassword}</p>
            )}
            <p className="mt-1.5 text-xs text-ink-400">Must be at least 6 characters</p>
          </div>

          <div>
            <label htmlFor="confirmPassword" className="label">
              Confirm New Password
            </label>
            <input
              id="confirmPassword"
              name="confirmPassword"
              type="password"
              required
              className={`input ${errors.confirmPassword ? 'input-error' : ''}`}
              placeholder="Confirm new password"
            />
            {errors.confirmPassword && (
              <p className="mt-1.5 text-sm text-red-600">{errors.confirmPassword}</p>
            )}
          </div>

          <button type="submit" disabled={loading} className="btn-primary">
            {loading ? 'Updating...' : 'Update Password'}
          </button>
        </form>
      </div>

      {/* Danger Zone */}
      <div className="card mt-6 border border-red-200 animate-in stagger-2">
        <h2 className="text-lg font-semibold text-red-600 mb-2">Danger Zone</h2>
        <p className="text-sm text-ink-500 mb-4">
          Sign out of your account on this device.
        </p>
        <button
          onClick={() => signOut({ callbackUrl: '/' })}
          className="btn-danger"
        >
          Sign Out
        </button>
      </div>
    </div>
  )
}
