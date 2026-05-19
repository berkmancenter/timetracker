import { mount } from '@vue/test-utils'
import { afterEach, describe, expect, it } from 'vitest'

import Sidebar from '../Sidebar.vue'

function mountSidebar(sudoMode = false) {
  return mount(Sidebar, {
    global: {
      mocks: {
        $store: {
          state: {
            shared: {
              user: { sudoMode },
            },
          },
        },
      },
      stubs: {
        MainMenu: { template: '<div class="main-menu-stub" />' },
        TimesheetSelect: { template: '<div class="timesheet-select-stub" />' },
        Popular: { template: '<div class="popular-stub" />' },
        Totals: { template: '<div class="totals-stub" />' },
        PeriodTotals: { template: '<div class="period-totals-stub" />' },
      },
    },
  })
}

describe('Sidebar', () => {
  afterEach(() => {
    document.body.classList.remove('tracker-entries')
  })

  it('renders tracker sidebar sections and adds the body class', () => {
    const wrapper = mountSidebar()

    expect(wrapper.find('.main-menu-stub').exists()).toBe(true)
    expect(wrapper.find('.timesheet-select-stub').exists()).toBe(true)
    expect(wrapper.find('.popular-stub').exists()).toBe(true)
    expect(wrapper.find('.totals-stub').exists()).toBe(true)
    expect(wrapper.find('.period-totals-stub').exists()).toBe(true)
    expect(document.body.classList.contains('tracker-entries')).toBe(true)
  })

  it('hides popular items in sudo mode and removes the body class on unmount', () => {
    const wrapper = mountSidebar(true)

    expect(wrapper.find('.popular-stub').exists()).toBe(false)

    wrapper.unmount()

    expect(document.body.classList.contains('tracker-entries')).toBe(false)
  })
})
