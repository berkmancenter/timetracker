import { mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import SwitMenu from '../SwitMenu.vue'

function createStore(sideMenuStatus = false) {
  return {
    state: {
      shared: {
        layout: {
          sideMenuStatus,
        },
      },
    },
    dispatch: vi.fn((action, status) => {
      if (action === 'shared/setSideMenuStatus') {
        store.state.shared.layout.sideMenuStatus = status
      }
    }),
  }
}

let store

function createMittMock() {
  const handlers = {}

  return {
    handlers,
    on: vi.fn((event, callback) => {
      handlers[event] = callback
    }),
  }
}

function mountSwitMenu(options = {}) {
  store = createStore(options.sideMenuStatus)
  const mitt = createMittMock()
  const wrapper = mount(SwitMenu, {
    attachTo: document.body,
    props: {
      buttonSelector: '#menu-button',
      contentSelector: '#content',
      closeOnClick: options.closeOnClick ?? true,
    },
    slots: {
      default: '<a href="/tracker">Tracker</a>',
    },
    global: {
      mocks: {
        $store: store,
        mitt,
      },
    },
  })

  return { wrapper, mitt, store }
}

describe('SwitMenu', () => {
  beforeEach(() => {
    document.body.innerHTML = '<button id="menu-button"></button><main id="content"></main>'
    document.querySelector('html').className = ''
  })

  afterEach(() => {
    document.querySelector('html').className = ''
  })

  it('marks the menu active from store state', () => {
    const { wrapper } = mountSwitMenu({ sideMenuStatus: true })

    expect(wrapper.classes()).toContain('switmenu-menu-active')
    expect(document.querySelector('html').classList.contains('switmenu-html-open')).toBe(true)
  })

  it('wires the menu button to toggle store state and content class', async () => {
    mountSwitMenu()

    document.querySelector('#menu-button').click()
    await Promise.resolve()

    expect(store.dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', true)
    expect(document.querySelector('#content').classList.contains('switmenu-content')).toBe(true)
    expect(document.querySelector('html').classList.contains('switmenu-html-open')).toBe(true)
  })

  it('closes the menu from the mitt event', () => {
    const { mitt, store } = mountSwitMenu({ sideMenuStatus: true })

    mitt.handlers.closeSideMenu()

    expect(store.dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', false)
    expect(document.querySelector('html').classList.contains('switmenu-html-open')).toBe(false)
  })

  it('closes the menu when a menu link is clicked by default', () => {
    const { wrapper, store } = mountSwitMenu({ sideMenuStatus: true })

    wrapper.find('a').element.onclick()

    expect(store.dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', false)
  })

  it('can leave the menu open when menu links are clicked', () => {
    const { wrapper, store } = mountSwitMenu({ sideMenuStatus: true, closeOnClick: false })

    expect(wrapper.find('a').element.onclick).toBeNull()

    expect(store.dispatch).not.toHaveBeenCalledWith('shared/setSideMenuStatus', false)
  })
})
