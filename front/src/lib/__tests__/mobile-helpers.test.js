import { afterEach, describe, expect, it, vi } from 'vitest'

import { isTouchDevice } from '../mobile-helpers'

describe('isTouchDevice', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('detects the touch event API', () => {
    vi.stubGlobal('window', { ontouchstart: undefined })
    vi.stubGlobal('navigator', { maxTouchPoints: 0, msMaxTouchPoints: 0 })

    expect(isTouchDevice()).toBe(true)
  })

  it('detects standard navigator touch points', () => {
    vi.stubGlobal('window', {})
    vi.stubGlobal('navigator', { maxTouchPoints: 2, msMaxTouchPoints: 0 })

    expect(isTouchDevice()).toBe(true)
  })

  it('returns false when no touch interface is available', () => {
    vi.stubGlobal('window', {})
    vi.stubGlobal('navigator', { maxTouchPoints: 0, msMaxTouchPoints: 0 })

    expect(isTouchDevice()).toBe(false)
  })
})
