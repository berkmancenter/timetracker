import { flushPromises, mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const router = vi.hoisted(() => ({ redirectToSelectedMonth: vi.fn() }))

vi.mock('@/router/index', () => router)

import DefaultLayout from '../Default.vue'

function mountLayout({ routeName = 'tracker.index', sideMenuEnabled = true } = {}) {
  const user = { username: 'ada@example.com', sudo_users: [] }
  const dispatch = vi.fn(async (action) => (action === 'shared/fetchUser' ? user : undefined))
  const emit = vi.fn()
  const store = {
    state: {
      shared: {
        layout: { sideMenuEnabled },
        user: { username: 'ada@example.com' },
      },
    },
    dispatch,
  }

  const wrapper = mount(DefaultLayout, {
    global: {
      mocks: {
        $store: store,
        $route: { name: routeName },
        mitt: { emit },
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
        SwitMenu: { template: '<div class="swit-menu-stub"><slot /></div>' },
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

  return { wrapper, dispatch, emit, store, user }
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

  it('shows the signed in user, the page and the sidebar', () => {
    const { wrapper } = mountLayout()

    expect(wrapper.find('.dropdown-stub').text()).toContain('ada@example.com')
    expect(wrapper.find('.swit-menu-stub .router-view-stub[data-name="Sidebar"]').exists()).toBe(true)
    expect(wrapper.find('.side-menu-toggler').exists()).toBe(true)
    expect(wrapper.find('.timetracker-content .router-view-stub').exists()).toBe(true)
    expect(wrapper.find('#footer').text()).toContain(`${new Date().getFullYear()}`)
  })

  it('hides the side menu when it is not enabled', () => {
    const { wrapper } = mountLayout({ sideMenuEnabled: false })

    expect(wrapper.find('.swit-menu-stub').exists()).toBe(false)
    expect(wrapper.find('.side-menu-toggler').exists()).toBe(false)
  })

  it('marks the menu item of the current page', () => {
    const tracker = mountLayout({ routeName: 'tracker.index' }).wrapper
    expect(menuLink(tracker, 'tracker.index').classes()).toContain('top-nav-button-menu-active')
    expect(menuLink(tracker, 'timesheets.index').classes()).not.toContain('top-nav-button-menu-active')

    const timesheets = mountLayout({ routeName: 'timesheets.index' }).wrapper
    expect(menuLink(timesheets, 'tracker.index').classes()).not.toContain('top-nav-button-menu-active')
    expect(menuLink(timesheets, 'timesheets.index').classes()).toContain('top-nav-button-menu-active')

    const other = mountLayout({ routeName: 'periods.stats' }).wrapper
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
