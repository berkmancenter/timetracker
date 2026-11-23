import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Spinner from '../Spinner.vue'

function createMittMock() {
  const handlers = {}

  return {
    handlers,
    on: vi.fn((event, callback) => {
      handlers[event] = callback
    }),
    off: vi.fn(),
  }
}

describe('Spinner', () => {
  it('starts and stops from mitt events', async () => {
    const mitt = createMittMock()
    const wrapper = mount(Spinner, {
      global: {
        mocks: {
          mitt,
        },
      },
    })

    expect(wrapper.find('.timetracker-spinner').exists()).toBe(false)

    mitt.handlers.spinnerStart()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.timetracker-spinner').exists()).toBe(true)
    expect(wrapper.find('img').attributes('src')).toBeTruthy()

    mitt.handlers.spinnerStop()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.timetracker-spinner').exists()).toBe(false)
  })

  it('removes its event listeners when unmounted', () => {
    const mitt = createMittMock()
    const wrapper = mount(Spinner, {
      global: {
        mocks: {
          mitt,
        },
      },
    })

    wrapper.unmount()

    expect(mitt.off).toHaveBeenCalledWith('spinnerStart', mitt.handlers.spinnerStart)
    expect(mitt.off).toHaveBeenCalledWith('spinnerStop', mitt.handlers.spinnerStop)
  })
})
