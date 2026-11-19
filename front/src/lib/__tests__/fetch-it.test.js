import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('@/main.js', () => ({ globals: {} }))

describe('fetchIt', () => {
  let fetchIt

  beforeEach(async () => {
    vi.resetModules()
    vi.stubGlobal('fetch', vi.fn())
    vi.stubEnv('VITE_ENVIRONMENT', 'test')
    fetchIt = (await import('../fetch-it')).default
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.unstubAllEnvs()
  })

  it('sends JSON headers while preserving the remaining request options', async () => {
    const response = { ok: true }
    fetch.mockResolvedValue(response)

    await expect(fetchIt('/entries', { method: 'POST', body: '{"hours":2}' })).resolves.toBe(response)
    expect(fetch).toHaveBeenCalledWith('/entries', {
      method: 'POST',
      body: '{"hours":2}',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    })
  })

  it('uses GET-compatible defaults when options are omitted', async () => {
    const response = { ok: true }
    fetch.mockResolvedValue(response)

    await fetchIt('/ping')

    expect(fetch).toHaveBeenCalledWith('/ping', {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    })
  })

  it('includes credentials for the cross-origin development server', async () => {
    vi.resetModules()
    vi.stubEnv('VITE_ENVIRONMENT', 'development')
    fetchIt = (await import('../fetch-it')).default
    fetch.mockResolvedValue({ ok: true })

    await fetchIt('/ping')

    expect(fetch).toHaveBeenCalledWith('/ping', expect.objectContaining({
      credentials: 'include',
    }))
  })

  it('rejects with the network error message when fetch fails', async () => {
    fetch.mockRejectedValue(new Error('network unavailable'))

    await expect(fetchIt('/entries')).rejects.toBe('network unavailable')
  })
})
