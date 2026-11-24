import { afterEach, describe, expect, it, vi } from 'vitest'

import { authType } from '../app-settings'

const addMeta = (name, content) => {
  const meta = document.createElement('meta')
  meta.name = name
  meta.content = content
  document.head.appendChild(meta)
}

describe('authType', () => {
  afterEach(() => {
    document.head.innerHTML = ''
    vi.unstubAllEnvs()
  })

  it('uses the auth type the server put in the page', () => {
    vi.stubEnv('VITE_AUTH_TYPE', 'db')
    addMeta('timetracker-auth-type', 'cas')

    expect(authType()).toBe('cas')
  })

  it('falls back to VITE_AUTH_TYPE when the page has no auth type', () => {
    vi.stubEnv('VITE_AUTH_TYPE', 'saml')

    expect(authType()).toBe('saml')
  })
})
