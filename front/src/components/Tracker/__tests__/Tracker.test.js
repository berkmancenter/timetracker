import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  redirectToSelectedMonth: vi.fn(),
}))

vi.mock('@/router/index', () => ({
  redirectToSelectedMonth: mocks.redirectToSelectedMonth,
}))

import Tracker from '../Tracker.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(timesheets = [{ id: 1, uuid: 'alpha' }]) {
  const state = {
    tracker: {
      selectedTimesheet: timesheets[0] || {},
    },
  }

  const dispatch = vi.fn(async (action) => {
    if (action === 'tracker/fetchTimesheets') return timesheets
    if (action === 'tracker/fetchMonths') return ['May 2026']
    return undefined
  })

  return { state, dispatch }
}

function mountTracker(store) {
  const emit = vi.fn()
  const wrapper = mount(Tracker, {
    global: {
      mocks: {
        $store: store,
        $route: { params: {} },
        mitt: { emit },
      },
      stubs: {
        EntryForm: { template: '<div class="entry-form-stub" />' },
        Entries: { template: '<div class="entries-stub" />' },
      },
    },
  })

  return { wrapper, emit }
}

describe('Tracker', () => {
  it('renders tracker content when a timesheet is selected', async () => {
    const store = createStore()
    const { wrapper } = mountTracker(store)

    await flushPromises()

    expect(wrapper.find('.entry-form-stub').exists()).toBe(true)
    expect(wrapper.find('.entries-stub').exists()).toBe(true)
  })

  it('loads initial data and redirects to the selected month', async () => {
    const store = createStore()
    const { emit } = mountTracker(store)

    await flushPromises()

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/fetchTimesheets')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setTimesheets', [{ id: 1, uuid: 'alpha' }])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setSelectedTimesheetFromRoute')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setMonths', ['May 2026'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['popular', 'entries', 'periodTotals', 'totals', 'users'])
    expect(mocks.redirectToSelectedMonth).toHaveBeenCalledWith(store)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('renders empty guidance and stops loading when there are no timesheets', async () => {
    const store = createStore([])
    const { wrapper, emit } = mountTracker(store)

    await flushPromises()

    expect(wrapper.text()).toContain('Select a timesheet or create new to add new entries.')
    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/fetchMonths')
    expect(mocks.redirectToSelectedMonth).toHaveBeenCalledWith(store)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('reloads route-dependent data when route params change after initial navigation', async () => {
    const store = createStore()
    const { wrapper } = mountTracker(store)

    await flushPromises()
    await wrapper.vm.$options.watch['$route.params'].handler.call(wrapper.vm, { month: 'June 2026' }, { month: 'May 2026' })

    expect(store.dispatch).toHaveBeenCalledWith('tracker/setSelectedTimesheetFromRoute')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setSelectedMonthFromRoute')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['entries', 'periodTotals', 'totals', 'users'])
  })
})
