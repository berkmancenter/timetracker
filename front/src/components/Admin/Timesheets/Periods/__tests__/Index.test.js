import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Index from '../Index.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(response = { ok: true }) {
  const state = {
    admin: {
      timesheet: { id: 9, name: 'Alpha' },
      periods: [
        { id: 2, name: 'Zeta', from: '2026-05-01', to: '2026-05-31' },
        { id: 1, name: 'Alpha period', from: '2026-04-01', to: '2026-04-30' },
      ],
    },
  }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchPeriods') return state.admin.periods
    if (action === 'admin/fetchTimesheet') return state.admin.timesheet
    if (action === 'admin/deletePeriods') return response
    if (action === 'admin/clonePeriod') return response
    return undefined
  })

  return { state, dispatch }
}

function mountIndex(store = createStore()) {
  const push = vi.fn()
  const emit = vi.fn()
  const awn = { success: vi.fn(), warning: vi.fn() }
  const wrapper = mount(Index, {
    global: {
      mocks: {
        $store: store,
        $route: { params: { timesheet_id: '9' } },
        $router: { push },
        mitt: { emit },
        awn,
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        RouterLink: { props: ['to'], template: '<a><slot /></a>' },
        ActionButton: { props: ['buttonText'], template: '<button>{{ buttonText }}</button>' },
        AdminTable: { template: '<table><slot /></table>' },
        Modal: { template: '<div><slot /></div>' },
        Icon: true,
      },
    },
  })

  return { wrapper, store, push, emit, awn }
}

describe('Admin Periods Index', () => {
  it('loads periods and timesheet data', async () => {
    const { wrapper, store, emit } = mountIndex()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchPeriods', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/setPeriods', store.state.admin.periods)
    expect(store.dispatch).toHaveBeenCalledWith('admin/setTimesheet', store.state.admin.timesheet)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.orderedPeriods.map((period) => period.name)).toEqual(['Alpha period', 'Zeta'])
  })

  it('deletes a period', async () => {
    const { wrapper, store, awn } = mountIndex()
    const period = store.state.admin.periods[0]

    wrapper.vm.deletePeriodConfirm(period)
    await wrapper.vm.deletePeriod()

    expect(store.dispatch).toHaveBeenCalledWith('admin/deletePeriods', { periods: [2], timesheetId: 9 })
    expect(awn.success).toHaveBeenCalledWith('Period has been removed.')
    expect(wrapper.vm.deletePeriodModalStatus).toBe(false)
  })

  it('clones a period', async () => {
    const { wrapper, store, awn } = mountIndex()

    await wrapper.vm.clonePeriod(store.state.admin.periods[0])

    expect(store.dispatch).toHaveBeenCalledWith('admin/clonePeriod', { periodId: 2, timesheetId: 9 })
    expect(awn.success).toHaveBeenCalledWith('Period "Zeta" has been cloned.')
  })

  it('navigates to period stats unless an action cell was clicked', () => {
    const { wrapper, push } = mountIndex()

    wrapper.vm.goToPeriodStats(2, { button: 0, target: { closest: () => null } })
    expect(push).toHaveBeenCalledWith('/admin/timesheets/9/periods/2/stats')

    push.mockClear()
    wrapper.vm.goToPeriodStats(2, { button: 0, target: { closest: () => ({}) } })
    expect(push).not.toHaveBeenCalled()
  })
})
