import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ commit: vi.fn() }))

vi.mock('@/store/index', () => ({ default: { commit: mocks.commit } }))

const answer = ({ status = 200, type = 'basic', body = {} } = {}) => ({
  status,
  type,
  ok: status >= 200 && status < 300,
  json: vi.fn().mockResolvedValue(body),
})

const addVersionToPage = (version) => {
  const meta = document.createElement('meta')
  meta.name = 'timetracker-version'
  meta.content = version
  document.head.appendChild(meta)
}

describe('server ping', () => {
  let reload
  let fakeWindow
  let pingServer

  beforeEach(async () => {
    mocks.commit.mockClear()
    reload = vi.fn()
    fakeWindow = Object.assign(new EventTarget(), { location: { reload } })
    vi.useFakeTimers()
    vi.stubGlobal('window', fakeWindow)
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(answer({ body: { version: 'abc' } })))
    addVersionToPage('abc')
    vi.resetModules()

    pingServer = (await import('../server-ping')).pingServer
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.unstubAllGlobals()
    document.head.innerHTML = ''
  })

  it('pings the server every minute without following redirects', async () => {
    await vi.advanceTimersByTimeAsync(59999)
    expect(fetch).not.toHaveBeenCalled()

    await vi.advanceTimersByTimeAsync(1)
    expect(fetch).toHaveBeenCalledTimes(1)
    expect(fetch).toHaveBeenCalledWith(`${import.meta.env.VITE_API_URL}/ping`, expect.objectContaining({
      credentials: 'include',
      redirect: 'manual',
      headers: { 'Accept': 'application/json' },
      signal: expect.any(AbortSignal),
    }))

    await vi.advanceTimersByTimeAsync(60000)
    expect(fetch).toHaveBeenCalledTimes(2)
  })

  it('keeps the page while the user is signed in and the version is the same', async () => {
    await expect(pingServer()).resolves.toBe('ok')

    expect(reload).not.toHaveBeenCalled()
    expect(mocks.commit).toHaveBeenCalledWith('shared/setServerReachable', true)
    expect(mocks.commit).not.toHaveBeenCalledWith('shared/setNewVersion')
  })

  it('tells the app when the server has a new version', async () => {
    fetch.mockResolvedValue(answer({ body: { version: 'def' } }))

    await expect(pingServer()).resolves.toBe('ok')

    expect(mocks.commit).toHaveBeenCalledWith('shared/setNewVersion')
    expect(reload).not.toHaveBeenCalled()
  })

  it('does not compare versions when the page has none, like on the Vite dev server', async () => {
    document.head.innerHTML = ''
    fetch.mockResolvedValue(answer({ body: { version: 'def' } }))

    await pingServer()

    expect(mocks.commit).not.toHaveBeenCalledWith('shared/setNewVersion')
  })

  it('reloads the page when the session ended', async () => {
    fetch.mockResolvedValue(answer({ status: 401 }))

    await expect(pingServer()).resolves.toBe('signed-out')

    expect(reload).toHaveBeenCalled()
  })

  it('reloads the page when the ping is redirected to a sign in page', async () => {
    fetch.mockResolvedValue(answer({ status: 0, type: 'opaqueredirect' }))

    await expect(pingServer()).resolves.toBe('signed-out')

    expect(reload).toHaveBeenCalled()
  })

  it.each([
    ['the network fails', () => fetch.mockRejectedValue(new TypeError('Failed to fetch'))],
    ['a proxy says the app is down', () => fetch.mockResolvedValue(answer({ status: 502 }))],
    ['the server does not answer in time', () => fetch.mockRejectedValue(new DOMException('Timed out', 'TimeoutError'))],
  ])('keeps the page and tells the app the server is unreachable when %s', async (_, failPing) => {
    failPing()

    await expect(pingServer()).resolves.toBe('unreachable')

    expect(reload).not.toHaveBeenCalled()
    expect(mocks.commit).toHaveBeenCalledWith('shared/setServerReachable', false)
  })

  it('tries again sooner while the server is unreachable', async () => {
    fetch.mockRejectedValue(new TypeError('Failed to fetch'))
    await vi.advanceTimersByTimeAsync(60000)
    expect(fetch).toHaveBeenCalledTimes(1)

    fetch.mockResolvedValue(answer({ body: { version: 'abc' } }))
    await vi.advanceTimersByTimeAsync(10000)
    expect(fetch).toHaveBeenCalledTimes(2)
    expect(mocks.commit).toHaveBeenLastCalledWith('shared/setServerReachable', true)

    await vi.advanceTimersByTimeAsync(10000)
    expect(fetch).toHaveBeenCalledTimes(2)
  })

  it('sends one ping at a time', async () => {
    await Promise.all([pingServer(), pingServer()])

    expect(fetch).toHaveBeenCalledTimes(1)
  })

  it('shows the server as unreachable as soon as the browser goes offline', () => {
    fakeWindow.dispatchEvent(new Event('offline'))

    expect(mocks.commit).toHaveBeenCalledWith('shared/setServerReachable', false)
  })

  it('pings at once when the browser is back online', async () => {
    fakeWindow.dispatchEvent(new Event('online'))
    await vi.advanceTimersByTimeAsync(0)

    expect(fetch).toHaveBeenCalledTimes(1)
  })
})
