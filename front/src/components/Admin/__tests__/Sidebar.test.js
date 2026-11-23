import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import Sidebar from '../Sidebar.vue'

describe('AdminSidebar', () => {
  it('renders the navigation menu without mutating document.body classes', () => {
    const wrapper = mount(Sidebar, {
      global: {
        stubs: {
          MainMenu: { template: '<div class="main-menu-stub" />' },
        },
      },
    })

    expect(wrapper.find('.main-menu-stub').exists()).toBe(true)
    expect(document.body.classList.contains('tracker-admin')).toBe(false)
  })
})
