import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Invite from '../Invite.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(response = { ok: true }) {
  const state = {
    admin: {
      timesheet: { id: 1, name: 'Alpha' },
      timesheetInvitations: 'ada@example.com',
    },
  }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchTimesheet') return state.admin.timesheet
    if (action === 'admin/sendTimesheetInvitations') return response
    return undefined
  })

  return { state, dispatch }
}

function mountInvite(store = createStore()) {
  const push = vi.fn()
  const emit = vi.fn()
  const awn = { success: vi.fn(), warning: vi.fn() }
  const wrapper = mount(Invite, {
    global: {
      mocks: {
        $store: store,
        $route: { params: { id: '1' } },
        $router: { push },
        mitt: { emit },
        awn,
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        Icon: true,
      },
    },
  })

  return { wrapper, store, push, emit, awn }
}

describe('Admin Timesheets Invite', () => {
  it('resets invitations and loads the timesheet', async () => {
    const { wrapper, store, emit } = mountInvite()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/setTimesheetInvitations', '')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '1')
    expect(store.dispatch).toHaveBeenCalledWith('admin/setTimesheet', store.state.admin.timesheet)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.breadcrumbs.map((crumb) => crumb.text)).toEqual(['Timesheets', 'Alpha', 'Invite'])
  })

  it('sends invitations and redirects', async () => {
    const { wrapper, store, push, awn } = mountInvite()
    wrapper.vm.selectedRole = 'admin'

    await wrapper.vm.send()

    expect(store.dispatch).toHaveBeenCalledWith('admin/sendTimesheetInvitations', {
      timesheetId: 1,
      emails: 'ada@example.com',
      role: 'admin',
    })
    expect(awn.success).toHaveBeenCalledWith('Invitations have been sent out.')
    expect(push).toHaveBeenCalledWith({ path: '/admin/timesheets' })
  })

  it('warns when sending invitations fails', async () => {
    const { wrapper, awn } = mountInvite(createStore({ ok: false }))

    await wrapper.vm.send()

    expect(awn.warning).toHaveBeenCalledWith('Something went wrong, try again.')
  })
})
