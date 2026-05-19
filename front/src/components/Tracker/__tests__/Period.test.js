import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Period from '../Period.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore() {
  const state = {
    tracker: {
      selectedTimesheet: { id: 1, uuid: 'alpha' },
      period: {
        id: 9,
        name: 'Spring',
        from: '2026-05-01',
        to: '2026-05-31',
        timesheet: { name: 'Alpha' },
      },
      periodUser: { id: 4, email: 'ada@example.com' },
    },
  }

  const dispatch = vi.fn(async (action) => {
    if (action === 'tracker/fetchTimesheets') return [{ id: 1, uuid: 'alpha' }]
    if (action === 'admin/fetchPeriod') return state.tracker.period
    if (action === 'tracker/fetchUser') return state.tracker.periodUser
    return undefined
  })

  return { state, dispatch }
}

function mountPeriod(store = createStore()) {
  const emit = vi.fn()
  const wrapper = mount(Period, {
    global: {
      mocks: {
        $store: store,
        $route: {
          params: {
            timesheet: 'alpha',
            period_id: '9',
            user_id: '4',
          },
        },
        mitt: { emit },
      },
      stubs: {
        Entries: {
          props: ['periodsView'],
          template: '<div class="entries-stub" :data-periods-view="periodsView" />',
        },
        RouterLink: {
          props: ['to'],
          template: '<a class="router-link-stub" :data-route-name="to.name"><slot /></a>',
        },
      },
    },
  })

  return { wrapper, emit, store }
}

describe('Period', () => {
  it('renders period summary and back route', async () => {
    const { wrapper } = mountPeriod()

    await flushPromises()

    expect(wrapper.text()).toContain('Alpha')
    expect(wrapper.text()).toContain('Spring')
    expect(wrapper.text()).toContain('ada@example.com')
    expect(wrapper.find('.router-link-stub').attributes('data-route-name')).toBe('periods.stats')
    expect(wrapper.find('.entries-stub').attributes('data-periods-view')).toBe('true')
  })

  it('loads period view data on creation', async () => {
    const { store, emit } = mountPeriod()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/setPeriodView', true)
    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/fetchTimesheets')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setSelectedTimesheetFromRoute')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchPeriod', { timesheetId: 'alpha', periodId: '9' })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/fetchUser', '4')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'], '9')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('clears period view state when unmounted', () => {
    const { wrapper, store } = mountPeriod()

    wrapper.unmount()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/setPeriodView', false)
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setPeriodUser', null)
  })

  it('returns no back route without selected timesheet and period ids', () => {
    const store = createStore()
    store.state.tracker.selectedTimesheet = {}
    store.state.tracker.period = {}

    const { wrapper } = mountPeriod(store)

    expect(wrapper.vm.periodStatsRoute).toBeNull()
  })
})
