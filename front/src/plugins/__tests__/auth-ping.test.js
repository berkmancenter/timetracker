import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

class FakeRequest {
  static all = []

  constructor() {
    this.responseURL = ''
    this.status = 200
    this.open = vi.fn()
    this.send = vi.fn()
    FakeRequest.all.push(this)
  }

  answer({ responseURL = '', status = 200 } = {}) {
    this.responseURL = responseURL
    this.status = status
    this.onreadystatechange()
  }
}

describe('auth ping', () => {
  let reload
  let navigator

  beforeEach(async () => {
    FakeRequest.all = []
    reload = vi.fn()
    navigator = { onLine: true }
    vi.useFakeTimers()
    vi.stubGlobal('XMLHttpRequest', FakeRequest)
    vi.stubGlobal('window', { location: { reload }, navigator })
    vi.resetModules()

    await import('../auth-ping')
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.unstubAllGlobals()
  })

  it('pings the server with credentials every minute', () => {
    vi.advanceTimersByTime(59999)
    expect(FakeRequest.all).toHaveLength(0)

    vi.advanceTimersByTime(1)
    expect(FakeRequest.all).toHaveLength(1)
    expect(FakeRequest.all[0].open).toHaveBeenCalledWith('GET', `${import.meta.env.VITE_API_URL}/ping`, true)
    expect(FakeRequest.all[0].withCredentials).toBe(true)
    expect(FakeRequest.all[0].send).toHaveBeenCalled()

    vi.advanceTimersByTime(60000)
    expect(FakeRequest.all).toHaveLength(2)
  })

  it('does not reload the page when the user is still signed in', () => {
    vi.advanceTimersByTime(60000)

    FakeRequest.all[0].answer({ responseURL: 'http://localhost/ping', status: 200 })

    expect(reload).not.toHaveBeenCalled()
  })

  it('reloads the page when the ping is sent to the sign in page', () => {
    vi.advanceTimersByTime(60000)

    FakeRequest.all[0].answer({ responseURL: 'http://localhost/users/sign_in', status: 200 })

    expect(reload).toHaveBeenCalled()
  })

  it('reloads the page when the server cannot be reached while online', () => {
    vi.advanceTimersByTime(60000)

    FakeRequest.all[0].answer({ status: 0 })

    expect(reload).toHaveBeenCalled()
  })

  it('does not reload the page while offline', () => {
    navigator.onLine = false
    vi.advanceTimersByTime(60000)

    FakeRequest.all[0].answer({ status: 0 })

    expect(reload).not.toHaveBeenCalled()
  })
})
