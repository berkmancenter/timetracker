import { mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'

import ServerNotice from '../ServerNotice.vue'

const mountNotice = (server) => mount(ServerNotice, {
  global: {
    mocks: {
      $store: { state: { shared: { server } } },
    },
  },
})

describe('ServerNotice', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('shows nothing while the server is reachable and has the same version', () => {
    const wrapper = mountNotice({ reachable: true, newVersion: false })

    expect(wrapper.find('.server-notice').exists()).toBe(false)
    expect(wrapper.find('.server-notice-area').attributes('aria-live')).toBe('polite')
  })

  it('says when the server cannot be reached', () => {
    const wrapper = mountNotice({ reachable: false, newVersion: false })

    expect(wrapper.find('.server-notice--unreachable').text()).toContain("Can't reach the server")
  })

  it('offers to reload the page when a new version is deployed', () => {
    const wrapper = mountNotice({ reachable: true, newVersion: true })
    const reload = vi.fn()
    vi.stubGlobal('window', { location: { reload } })

    expect(wrapper.find('.server-notice').text()).toContain('A new version of Timetracker is ready')
    wrapper.find('button').element.click()

    expect(reload).toHaveBeenCalled()
  })

  it('says only that the server cannot be reached when there is a new version too', () => {
    const wrapper = mountNotice({ reachable: false, newVersion: true })

    expect(wrapper.findAll('.server-notice')).toHaveLength(1)
    expect(wrapper.find('.server-notice--unreachable').exists()).toBe(true)
  })
})
