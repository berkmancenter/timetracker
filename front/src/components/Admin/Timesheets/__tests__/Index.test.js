import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Index from '../Index.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(response = { ok: true }) {
  const state = {
    admin: {
      timesheets: [
        { id: 2, name: 'Zebra', roles: ['user'], created_at: '2026-05-02T10:00:00Z' },
        { id: 1, name: 'Alpha', roles: ['admin'], created_at: '2026-05-01T10:00:00Z' },
      ],
    },
  }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchTimesheets') return state.admin.timesheets
    if (action === 'admin/deleteTimesheets') return response
    if (action === 'admin/leaveTimesheet') return response
    return undefined
  })

  return { state, dispatch }
}

function mountIndex(store = createStore()) {
  const emit = vi.fn()
  const awn = { success: vi.fn(), warning: vi.fn() }
  const wrapper = mount(Index, {
    global: {
      mocks: {
        $store: store,
        mitt: { emit },
        awn,
      },
      stubs: {
        RouterLink: {
          props: ['to'],
          template: '<a class="router-link-stub" :data-to="to"><slot /></a>',
        },
        ActionButton: { props: ['buttonText'], template: '<button>{{ buttonText }}</button>' },
        AdminTable: { template: '<table><slot /></table>' },
        Icon: { template: '<img>' },
        Modal: { template: '<div />' },
      },
    },
  })

  return { wrapper, emit, awn, store }
}

describe('Admin Timesheets Index', () => {
  it('loads and renders ordered timesheets', async () => {
    const { wrapper, store, emit } = mountIndex()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheets')
    expect(store.dispatch).toHaveBeenCalledWith('admin/setTimesheets', store.state.admin.timesheets)
    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.orderedTimesheets.map((timesheet) => timesheet.name)).toEqual(['Alpha', 'Zebra'])
    expect(wrapper.text()).toContain('Alpha')
  })

  it('opens and confirms remove timesheet workflow', async () => {
    const { wrapper, store, awn } = mountIndex()
    const timesheet = store.state.admin.timesheets[1]

    wrapper.vm.removeTimesheetConfirm(timesheet)
    expect(wrapper.vm.removeTimesheetModalStatus).toBe(true)

    await wrapper.vm.removeTimesheet()

    expect(store.dispatch).toHaveBeenCalledWith('admin/deleteTimesheets', [timesheet.id])
    expect(awn.success).toHaveBeenCalledWith('Timesheet has been removed.')
    expect(wrapper.vm.removeTimesheetModalStatus).toBe(false)
  })

  it('opens and confirms leave timesheet workflow', async () => {
    const { wrapper, store, awn } = mountIndex()
    const timesheet = store.state.admin.timesheets[0]

    wrapper.vm.leaveTimesheetConfirm(timesheet)
    await wrapper.vm.leaveTimesheet()

    expect(store.dispatch).toHaveBeenCalledWith('admin/leaveTimesheet', timesheet)
    expect(awn.success).toHaveBeenCalledWith('You have left the timesheet successfully.')
    expect(wrapper.vm.leaveTimesheetModalStatus).toBe(false)
  })

  it('warns when removing fails', async () => {
    const { wrapper, awn } = mountIndex(createStore({ ok: false }))

    wrapper.vm.removeTimesheetConfirm({ id: 1, name: 'Alpha' })
    await wrapper.vm.removeTimesheet()

    expect(awn.warning).toHaveBeenCalledWith('Something went wrong, try again.')
  })
})
