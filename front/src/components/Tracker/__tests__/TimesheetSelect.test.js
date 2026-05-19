import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  redirectToSelectedMonth: vi.fn(),
}))

vi.mock('@/router/index', () => ({
  redirectToSelectedMonth: mocks.redirectToSelectedMonth,
}))

import TimesheetSelect from '../TimesheetSelect.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore() {
  const state = {
    tracker: {
      timesheets: [
        { id: 2, name: 'Zebra', uuid: 'zebra' },
        { id: 1, name: 'Alpha', uuid: 'alpha' },
      ],
      selectedTimesheet: { id: 2, uuid: 'zebra' },
    },
  }

  const dispatch = vi.fn(async (action, payload) => {
    if (action === 'tracker/setSelectedTimesheet') {
      state.tracker.selectedTimesheet = payload
    }

    if (action === 'tracker/fetchMonths') {
      return ['May 2026']
    }

    return undefined
  })

  return { state, dispatch }
}

describe('TimesheetSelect', () => {
  it('sorts timesheets and initializes the selected value', async () => {
    const store = createStore()
    const wrapper = mount(TimesheetSelect, {
      global: {
        mocks: {
          $store: store,
          $router: { push: vi.fn() },
          mitt: { emit: vi.fn() },
        },
      },
    })

    await wrapper.vm.$nextTick()

    expect(wrapper.findAll('option').map((option) => option.text())).toEqual(['Alpha', 'Zebra'])
    expect(wrapper.vm.selectedTimesheet).toBe(2)
  })

  it('changes the active timesheet and reloads dependent data', async () => {
    const store = createStore()
    const push = vi.fn()
    const emit = vi.fn()
    const wrapper = mount(TimesheetSelect, {
      global: {
        mocks: {
          $store: store,
          $router: { push },
          mitt: { emit },
        },
      },
    })

    await wrapper.find('select').setValue('1')
    await flushPromises()

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setSelectedTimesheet', { id: 1, name: 'Alpha', uuid: 'alpha' })
    expect(push).toHaveBeenCalledWith({ name: 'tracker.index', params: { timesheet: 'alpha', month: null } })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setMonths', ['May 2026'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setSelectedMonthFromRoute')
    expect(mocks.redirectToSelectedMonth).toHaveBeenCalledWith(store)
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'])
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })
})
