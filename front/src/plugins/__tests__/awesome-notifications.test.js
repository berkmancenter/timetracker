import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => {
  const instance = { success: vi.fn(), warning: vi.fn() }
  const AWN = function(options) {
    instance.options = options
    return instance
  }

  return { AWN, instance }
})

vi.mock('awesome-notifications', () => ({
  default: { default: mocks.AWN },
}))

import notifications from '../awesome-notifications'

describe('awesome notifications adapter', () => {
  it('unwraps the legacy CommonJS constructor and configures it', () => {
    expect(notifications).toBe(mocks.instance)
    expect(notifications.options).toEqual({
      position: 'top-right',
      durations: { global: 6000 },
      maxNotifications: 2,
      labels: {
        tip: '',
        info: '',
        warning: '',
        success: '',
      },
    })
  })
})
