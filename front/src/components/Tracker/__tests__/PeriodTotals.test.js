import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import PeriodTotals from '../PeriodTotals.vue'

function mountPeriodTotals({ mode = 'days', sudoMode = false, totals = [{ date: '2026-05-01', total_hours: 3, email: 'ada@example.com' }] } = {}) {
  const dispatch = vi.fn()
  const wrapper = mount(PeriodTotals, {
    global: {
      mocks: {
        $store: {
          state: {
            tracker: {
              periodTotals: totals,
              periodTotalsMode: mode,
            },
            shared: {
              user: { sudoMode },
            },
          },
          dispatch,
        },
      },
      stubs: {
        VDropdown: {
          template: '<div class="dropdown-stub"><slot /><slot name="popper" /></div>',
        },
      },
      directives: {
        closePopper: {},
      },
    },
  })

  return { wrapper, dispatch }
}

describe('PeriodTotals', () => {
  it('does not render when there are no totals', () => {
    const { wrapper } = mountPeriodTotals({ totals: [] })

    expect(wrapper.find('.tracker-period-totals').exists()).toBe(false)
  })

  it('renders daily totals and sudo email rows', () => {
    const { wrapper } = mountPeriodTotals({ sudoMode: true })

    expect(wrapper.find('h5').text()).toContain('Daily Totals')
    expect(wrapper.text()).toContain('2026-05-01')
    expect(wrapper.text()).toContain('3')
    expect(wrapper.text()).toContain('ada@example.com')
  })

  it('switches period totals mode', async () => {
    const { wrapper, dispatch } = mountPeriodTotals({ mode: 'weeks' })

    expect(wrapper.find('h5').text()).toContain('Weekly Totals')

    wrapper.vm.setMode('days')

    expect(dispatch).toHaveBeenCalledWith('tracker/setPeriodTotalsMode', 'days')
  })
})
