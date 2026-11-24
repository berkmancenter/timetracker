import { flushPromises } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => {
  const assign = vi.fn()
  const fakeWindow = Object.assign(new EventTarget(), { location: { assign } })
  vi.stubGlobal('window', fakeWindow)

  return {
    assign,
    fakeWindow,
    pingServer: vi.fn(),
    store: { state: { shared: { server: { newVersion: false } } } },
    loadPageFiles: vi.fn(),
  }
})

vi.mock('@/store/index', () => ({ default: mocks.store }))
vi.mock('@/plugins/server-ping', () => ({ pingServer: mocks.pingServer }))
vi.mock('@/router/index', async () => {
  const { createMemoryHistory, createRouter } = await import('vue-router')
  const page = { template: '<div />' }

  return {
    router: createRouter({
      history: createMemoryHistory('/timetracker/'),
      routes: [
        { path: '/', component: page },
        { path: '/admin/timesheets', component: page },
        { path: '/admin/timesheets/:id/edit', component: () => mocks.loadPageFiles() },
      ],
    }),
  }
})

import { router } from '@/router/index'
import '../new-version'

// What Vite does when the files of a lazy loaded page are gone
const filesAreGone = () => {
  mocks.loadPageFiles.mockImplementation(() => {
    const error = new TypeError('Failed to fetch dynamically imported module')
    const event = new Event('vite:preloadError', { cancelable: true })
    event.payload = error
    mocks.fakeWindow.dispatchEvent(event)

    return Promise.reject(error)
  })
}

describe('new version', () => {
  let consoleError

  beforeEach(async () => {
    mocks.store.state.shared.server.newVersion = false
    await router.push('/')
    sessionStorage.clear()
    mocks.assign.mockClear()
    mocks.pingServer.mockReset().mockResolvedValue('ok')
    mocks.loadPageFiles.mockReset()
    consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('opens pages in place while there is no new version', async () => {
    await router.push('/admin/timesheets')

    expect(router.currentRoute.value.fullPath).toBe('/admin/timesheets')
    expect(mocks.assign).not.toHaveBeenCalled()
  })

  it('loads the next page from the server once a new version is deployed', async () => {
    mocks.store.state.shared.server.newVersion = true

    await router.push('/admin/timesheets?sort=name')

    expect(mocks.assign).toHaveBeenCalledWith('/timetracker/admin/timesheets?sort=name')
    expect(router.currentRoute.value.fullPath).toBe('/')
  })

  it('opens the page in place when the page was loaded from the server a moment ago', async () => {
    mocks.store.state.shared.server.newVersion = true
    await router.push('/admin/timesheets')

    await router.push('/admin/timesheets?sort=name')

    expect(mocks.assign).toHaveBeenCalledTimes(1)
    expect(router.currentRoute.value.fullPath).toBe('/admin/timesheets?sort=name')
  })

  it('loads a page from the server when its files are gone after a deploy', async () => {
    filesAreGone()

    await router.push('/admin/timesheets/7/edit').catch(() => {})
    await flushPromises()

    expect(mocks.pingServer).toHaveBeenCalled()
    expect(mocks.assign).toHaveBeenCalledWith('/timetracker/admin/timesheets/7/edit')
    expect(consoleError).not.toHaveBeenCalled()
  })

  it('stays on the page when the server cannot be reached', async () => {
    filesAreGone()
    mocks.pingServer.mockResolvedValue('unreachable')

    await router.push('/admin/timesheets/7/edit').catch(() => {})
    await flushPromises()

    expect(mocks.assign).not.toHaveBeenCalled()
    expect(router.currentRoute.value.fullPath).toBe('/')
    expect(consoleError).toHaveBeenCalled()
  })

  it('does not load the page again and again when its files are missing on the new version too', async () => {
    filesAreGone()

    await router.push('/admin/timesheets/7/edit').catch(() => {})
    await flushPromises()
    await router.push('/admin/timesheets/7/edit').catch(() => {})
    await flushPromises()

    expect(mocks.assign).toHaveBeenCalledTimes(1)
    expect(consoleError).toHaveBeenCalledTimes(1)
  })

  it('only logs other errors of the router', async () => {
    const error = new Error('Broken page')
    mocks.loadPageFiles.mockRejectedValue(error)

    await router.push('/admin/timesheets/7/edit').catch(() => {})
    await flushPromises()

    expect(mocks.pingServer).not.toHaveBeenCalled()
    expect(mocks.assign).not.toHaveBeenCalled()
    expect(consoleError).toHaveBeenCalledWith(error)
  })
})
