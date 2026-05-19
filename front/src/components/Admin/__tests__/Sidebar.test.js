import { mount } from '@vue/test-utils'
import { afterEach, describe, expect, it } from 'vitest'

import Sidebar from '../Sidebar.vue'

describe('AdminSidebar', () => {
  afterEach(() => {
    document.body.classList.remove('tracker-admin')
  })

  it('renders the menu and manages the admin body class', () => {
    const wrapper = mount(Sidebar, {
      global: {
        stubs: {
          MainMenu: { template: '<div class="main-menu-stub" />' },
        },
      },
    })

    expect(wrapper.find('.main-menu-stub').exists()).toBe(true)
    expect(document.body.classList.contains('tracker-admin')).toBe(true)

    wrapper.unmount()

    expect(document.body.classList.contains('tracker-admin')).toBe(false)
  })
})
