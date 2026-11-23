import { flushPromises, mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const router = vi.hoisted(() => ({ redirectToSelectedMonth: vi.fn() }))

vi.mock('@/router/index', () => router)

import DefaultLayout from '../Default.vue'

function mountLayout({ routeName = 'tracker.index', sidebar = 'full', sideMenuStatus = false } = {}) {
  const user = { username: 'ada@example.com', sudo_users: [] }
  const handlers = {}
  const mitt = {
    handlers,
    emit: vi.fn(),
    on: vi.fn((event, handler) => {
      handlers[event] = handler
    }),
    off: vi.fn(),
  }
  const store = {
    state: {
      shared: {
        layout: { sideMenuStatus },
        user: { username: 'ada@example.com' },
      },
    },
    dispatch: vi.fn(async (action, payload) => {
      if (action === 'shared/fetchUser') return user
      if (action === 'shared/setSideMenuStatus') {
        store.state.shared.layout.sideMenuStatus = payload
      }
      return undefined
    }),
  }

  const wrapper = mount(DefaultLayout, {
    global: {
      mocks: {
        $store: store,
        $route: { name: routeName, meta: sidebar === undefined ? {} : { sidebar } },
        mitt,
      },
      stubs: {
        RouterLink: {
          props: ['to'],
          template: '<a class="router-link-stub" :data-route-name="to.name"><slot /></a>',
        },
        RouterView: {
          props: ['name'],
          template: '<div class="router-view-stub" :data-name="name" />',
        },
        Spinner: { template: '<div class="spinner-stub" />' },
        ModalsContainer: { template: '<div class="modals-container-stub" />' },
        Icon: { template: '<i class="icon-stub" />' },
        VDropdown: {
          template: '<div class="dropdown-stub"><slot /><slot name="popper" /></div>',
        },
      },
      directives: {
        closePopper: {},
      },
    },
  })

  return { wrapper, dispatch: store.dispatch, emit: mitt.emit, mitt, store, user }
}

function menuLink(wrapper, routeName) {
  return wrapper.find(`.router-link-stub[data-route-name="${routeName}"]`)
}

describe('DefaultLayout', () => {
  it('loads the current user when created', async () => {
    const { dispatch, user } = mountLayout()

    await flushPromises()

    expect(dispatch).toHaveBeenNthCalledWith(1, 'shared/fetchUser')
    expect(dispatch).toHaveBeenNthCalledWith(2, 'shared/setUser', user)
  })

  it('shows the signed in user, the page and the reactive sidebar shell', () => {
    const { wrapper } = mountLayout()

    expect(wrapper.find('.app-shell').classes()).toContain('app-shell--sidebar-full')
    expect(wrapper.find('.app-shell').classes()).not.toContain('app-shell--sidebar-open')
    expect(wrapper.find('.dropdown-stub').text()).toContain('ada@example.com')
    expect(wrapper.find('.app-sidebar .router-view-stub[data-name="Sidebar"]').exists()).toBe(true)
    expect(wrapper.find('.side-menu-toggler').exists()).toBe(true)
    expect(wrapper.find('.app-main .timetracker-content .router-view-stub').exists()).toBe(true)
    expect(wrapper.find('#footer').text()).toContain(`${new Date().getFullYear()}`)
  })

  it('applies mobile-only sidebar mode from route metadata', () => {
    const { wrapper } = mountLayout({ routeName: 'timesheets.index', sidebar: 'mobile-only' })

    expect(wrapper.find('.app-shell').classes()).toContain('app-shell--sidebar-mobile-only')
    expect(wrapper.find('.app-sidebar').exists()).toBe(true)
    expect(wrapper.find('.side-menu-toggler').exists()).toBe(true)
  })

  it('hides the sidebar and toggler when route meta disables the sidebar', () => {
    const { wrapper } = mountLayout({ routeName: 'timesheets.join', sidebar: 'none', sideMenuStatus: true })

    expect(wrapper.find('.app-shell').classes()).toContain('app-shell--sidebar-none')
    expect(wrapper.find('.app-shell').classes()).not.toContain('app-shell--sidebar-open')
    expect(wrapper.find('.app-sidebar').exists()).toBe(false)
    expect(wrapper.find('.side-menu-toggler').exists()).toBe(false)
  })

  it('toggles the sidebar via the store without touching document classes', async () => {
    const { wrapper, dispatch } = mountLayout({ sideMenuStatus: false })

    await wrapper.find('.side-menu-toggler').trigger('click')

    expect(dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', true)
    expect(document.documentElement.classList.contains('switmenu-html-open')).toBe(false)
    expect(document.body.classList.contains('tracker-entries')).toBe(false)
    expect(document.body.classList.contains('tracker-admin')).toBe(false)
  })

  it('reflects open sidebar state and closes on closeSideMenu event, cleaning up on unmount', () => {
    const { wrapper, dispatch, mitt } = mountLayout({ sideMenuStatus: true })

    expect(wrapper.find('.app-shell').classes()).toContain('app-shell--sidebar-open')
    expect(wrapper.find('.side-menu-toggler').attributes('aria-expanded')).toBe('true')
    expect(wrapper.find('.app-sidebar').attributes('aria-hidden')).toBe('false')

    mitt.handlers.closeSideMenu()
    expect(dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', false)

    wrapper.unmount()
    expect(mitt.off).toHaveBeenCalledWith('closeSideMenu', mitt.handlers.closeSideMenu)
  })

  it('marks the menu item of the current page', () => {
    const tracker = mountLayout({ routeName: 'tracker.index' }).wrapper
    expect(menuLink(tracker, 'tracker.index').classes()).toContain('top-nav-button-menu-active')
    expect(menuLink(tracker, 'timesheets.index').classes()).not.toContain('top-nav-button-menu-active')

    const timesheets = mountLayout({ routeName: 'timesheets.index', sidebar: 'mobile-only' }).wrapper
    expect(menuLink(timesheets, 'tracker.index').classes()).not.toContain('top-nav-button-menu-active')
    expect(menuLink(timesheets, 'timesheets.index').classes()).toContain('top-nav-button-menu-active')

    const other = mountLayout({ routeName: 'periods.stats', sidebar: 'mobile-only' }).wrapper
    expect(other.findAll('.top-nav-button-menu-active')).toHaveLength(0)
  })

  it('goes back to the selected month from the time entries link', async () => {
    const { wrapper, store } = mountLayout()

    await menuLink(wrapper, 'tracker.index').trigger('click')

    expect(router.redirectToSelectedMonth).toHaveBeenCalledWith(store)
  })

  it('starts the spinner and logs out', async () => {
    const { wrapper, dispatch, emit } = mountLayout()

    const logout = wrapper.findAll('.dropdown-item').find(item => item.text() === 'Logout')
    await logout.trigger('click')

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(dispatch).toHaveBeenCalledWith('shared/logout')
  })
})
