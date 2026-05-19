import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import Totals from '../Totals.vue'

function mountTotals(selectedMonth = 'May 2026') {
  return mount(Totals, {
    global: {
      mocks: {
        $store: {
          state: {
            tracker: {
              totalCurrentTimesheet: 42,
              totalCurrentMonth: 7.5,
              selectedMonth,
            },
          },
        },
      },
    },
  })
}

describe('Totals', () => {
  it('renders timesheet and current month totals', () => {
    const wrapper = mountTotals()

    expect(wrapper.text()).toContain('Total hours')
    expect(wrapper.text()).toContain('42')
    expect(wrapper.text()).toContain('Total hours in current month')
    expect(wrapper.text()).toContain('7.5')
  })

  it('hides the month total when all months are selected', () => {
    const wrapper = mountTotals('all')

    expect(wrapper.text()).not.toContain('Total hours in current month')
  })
})
