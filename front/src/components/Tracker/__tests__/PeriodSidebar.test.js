import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import PeriodSidebar from '../PeriodSidebar.vue'

describe('PeriodSidebar', () => {
  it('renders period sidebar sections without mutating document.body classes', () => {
    const wrapper = mount(PeriodSidebar, {
      global: {
        stubs: {
          MainMenu: { template: '<div class="main-menu-stub" />' },
          Totals: { template: '<div class="totals-stub" />' },
          PeriodTotals: { template: '<div class="period-totals-stub" />' },
        },
      },
    })

    expect(wrapper.find('.main-menu-stub').exists()).toBe(true)
    expect(wrapper.find('.totals-stub').exists()).toBe(true)
    expect(wrapper.find('.period-totals-stub').exists()).toBe(true)
    expect(document.body.classList.contains('tracker-entries')).toBe(false)
  })
})
