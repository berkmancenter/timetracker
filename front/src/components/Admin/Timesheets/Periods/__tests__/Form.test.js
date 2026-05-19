import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Form from '../Form.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(period = { id: 2, name: 'Spring', from: '2026-05-01', to: '2026-05-31', custom_fields: [] }, response = { ok: true }) {
  const state = {
    admin: {
      timesheet: { id: 9, name: 'Alpha' },
      period,
    },
  }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchAdminTimesheets') return [state.admin.timesheet]
    if (action === 'admin/fetchTimesheet') return state.admin.timesheet
    if (action === 'admin/fetchPeriod') return period
    if (action === 'admin/savePeriod') return response
    return undefined
  })

  return { state, dispatch }
}

function mountForm({ id, store = createStore() } = {}) {
  const push = vi.fn()
  const emit = vi.fn()
  const awn = { success: vi.fn(), warning: vi.fn() }
  const wrapper = mount(Form, {
    global: {
      mocks: {
        $store: store,
        $route: { params: { timesheet_id: '9', ...(id ? { id } : {}) } },
        $router: { push },
        mitt: { emit },
        awn,
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        CustomFields: { template: '<div class="custom-fields-stub" />' },
        DatePicker: { template: '<input>' },
        Icon: true,
      },
    },
  })

  return { wrapper, store, push, emit, awn }
}

describe('Admin Periods Form', () => {
  it('loads existing period data and formats dates', async () => {
    const store = createStore()
    const { wrapper, emit } = mountForm({ id: '2', store })

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/clearPeriod')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchAdminTimesheets')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchPeriod', { timesheetId: '9', periodId: '2' })
    expect(store.dispatch).toHaveBeenCalledWith('admin/setPeriod', expect.objectContaining({ from: 'May 1, 2026', to: 'May 31, 2026' }))
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.title).toBe('Edit period')
  })

  it('saves a period and redirects', async () => {
    const { wrapper, store, push, awn } = mountForm()

    await wrapper.vm.save()

    expect(store.state.admin.period.timesheet_id).toBe('9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/savePeriod', {
      timesheet_id: '9',
      period: store.state.admin.period,
    })
    expect(awn.success).toHaveBeenCalledWith('Period has been saved.')
    expect(push).toHaveBeenCalledWith({ path: '/admin/timesheets/9/periods' })
  })

  it('warns when save fails', async () => {
    const { wrapper, awn } = mountForm({ store: createStore(undefined, { ok: false }) })

    await wrapper.vm.save()

    expect(awn.warning).toHaveBeenCalledWith('Something went wrong, try again.')
  })
})
