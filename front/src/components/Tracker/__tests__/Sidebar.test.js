import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

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
  it('renders tracker sidebar sections without mutating document.body classes', () => {
    const wrapper = mountSidebar()

    expect(wrapper.find('.main-menu-stub').exists()).toBe(true)
    expect(wrapper.find('.timesheet-select-stub').exists()).toBe(true)
    expect(wrapper.find('.popular-stub').exists()).toBe(true)
    expect(wrapper.find('.totals-stub').exists()).toBe(true)
    expect(wrapper.find('.period-totals-stub').exists()).toBe(true)
    expect(document.body.classList.contains('tracker-entries')).toBe(false)
  })

  it('hides popular items in sudo mode', () => {
    const wrapper = mountSidebar(true)

    expect(wrapper.find('.popular-stub').exists()).toBe(false)
  })
})
