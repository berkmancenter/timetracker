import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Form from '../Form.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(timesheet = { id: 1, name: 'Alpha', custom_fields: [{ title: 'Project' }] }, response = { ok: true }) {
  const state = { admin: { timesheet } }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchTimesheet') return timesheet
    if (action === 'admin/saveTimesheet') return response
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
        $route: { params: id ? { id } : {} },
        $router: { push },
        mitt: { emit },
        awn,
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        CustomFields: { template: '<div class="custom-fields-stub"><slot name="additional-fields" :field="{ popular: false, list: false }" :index="0" /></div>' },
        Icon: true,
      },
    },
  })

  return { wrapper, push, emit, awn, store }
}

describe('Admin Timesheets Form', () => {
  it('clears and loads an existing timesheet', async () => {
    const store = createStore()
    const { wrapper, emit } = mountForm({ id: '1', store })

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/clearTimesheet')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '1')
    expect(store.dispatch).toHaveBeenCalledWith('admin/setTimesheet', store.state.admin.timesheet)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.title()).toBe('Edit timesheet')
    expect(wrapper.vm.breadcrumbs.map((crumb) => crumb.text)).toEqual(['Timesheets', 'Alpha', 'Edit timesheet'])
  })

  it('renders new timesheet title and breadcrumbs', () => {
    const { wrapper } = mountForm()

    expect(wrapper.vm.title()).toBe('New timesheet')
    expect(wrapper.vm.breadcrumbs.map((crumb) => crumb.text)).toEqual(['Timesheets', 'New timesheet'])
  })

  it('saves a valid timesheet and redirects', async () => {
    const { wrapper, store, push, awn } = mountForm()

    await wrapper.vm.save()

    expect(store.dispatch).toHaveBeenCalledWith('admin/saveTimesheet', store.state.admin.timesheet)
    expect(awn.success).toHaveBeenCalledWith('Timesheet has been saved.')
    expect(push).toHaveBeenCalledWith({ path: '/admin/timesheets' })
    expect(wrapper.vm.$refs.submitButton.disabled).toBe(false)
  })

  it('requires at least one non-destroyed field before saving', async () => {
    const store = createStore({ name: 'Alpha', custom_fields: [{ _destroy: true }] })
    const { wrapper, awn } = mountForm({ store })

    await wrapper.vm.save()

    expect(awn.warning).toHaveBeenCalledWith('You need at least 1 field to be able to save the timesheet.')
    expect(store.dispatch).not.toHaveBeenCalledWith('admin/saveTimesheet', expect.anything())
  })
})
