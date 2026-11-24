import { afterEach, describe, expect, it, vi } from 'vitest'

import { authType, frontVersion } from '../app-settings'

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

describe('frontVersion', () => {
  afterEach(() => {
    document.head.innerHTML = ''
  })

  it('uses the version the server put in the page', () => {
    addMeta('timetracker-version', '3f9a1c0b7d2e')

    expect(frontVersion()).toBe('3f9a1c0b7d2e')
  })

  it('has no version when the page does not come from the server', () => {
    expect(frontVersion()).toBeUndefined()
  })
})
