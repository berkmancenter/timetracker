import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Users from '../Users.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(response = { ok: true }) {
  const users = [
    { id: 1, email: 'ada@example.com', joined: '2026-05-01T10:00:00Z', roles: ['user'], selected: false },
    { id: 2, email: 'grace@example.com', joined: '2026-05-02T10:00:00Z', roles: ['admin'], selected: false },
  ]
  const timesheet = { id: 9, name: 'Alpha' }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchTimesheetUsers') return users
    if (action === 'admin/fetchTimesheet') return timesheet
    if (action === 'admin/deleteUsersFromTimesheet') return response
    if (action === 'admin/changeTimesheetUsersRole') return response
    return undefined
  })

  return { dispatch, users, timesheet }
}

function mountUsers(store = createStore()) {
  const emit = vi.fn()
  const awn = { success: vi.fn(), warning: vi.fn() }
  const wrapper = mount(Users, {
    global: {
      mocks: {
        $store: store,
        $route: { params: { id: '9' } },
        mitt: { emit },
        awn,
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        SuperAdminFilter: { props: ['users'], template: '<div class="filter-stub" />' },
        AdminTable: { template: '<table><slot /></table>' },
        Modal: { template: '<div />' },
        ActionButton: true,
        Icon: true,
      },
    },
  })

  return { wrapper, emit, awn, store }
}

describe('Admin Timesheet Users', () => {
  it('loads users and timesheet data', async () => {
    const { wrapper, store, emit } = mountUsers()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheetUsers', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '9')
    expect(wrapper.vm.users).toEqual(store.users)
    expect(wrapper.vm.filteredItems).toEqual(store.users)
    expect(wrapper.vm.timesheet).toEqual(store.timesheet)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.breadcrumbs.map((crumb) => crumb.text)).toEqual(['Timesheets', 'Alpha', 'Users'])
  })

  it('toggles all users', async () => {
    const { wrapper } = mountUsers()
    await flushPromises()

    wrapper.vm.$refs.toggleAllCheckbox.checked = true
    wrapper.vm.toggleAll()

    expect(wrapper.vm.users.every((user) => user.selected)).toBe(true)
  })

  it('removes a user from the timesheet', async () => {
    const { wrapper, store, awn } = mountUsers()
    await flushPromises()

    wrapper.vm.removeFromTimesheetConfirm(store.users[0])
    expect(wrapper.vm.removeUserFromTimesheetModalStatus).toBe(true)

    await wrapper.vm.removeUserFromTimesheet()

    expect(store.dispatch).toHaveBeenCalledWith('admin/deleteUsersFromTimesheet', {
      users: [1],
      timesheetId: '9',
    })
    expect(awn.success).toHaveBeenCalledWith('Users have been removed.')
    expect(wrapper.vm.removeUserFromTimesheetModalStatus).toBe(false)
  })

  it('changes a user role', async () => {
    const { wrapper, store, awn } = mountUsers()
    await flushPromises()

    wrapper.vm.changeUsersRoleModalOpen(store.users[1])
    wrapper.vm.changeUsersRoleSelected = 'user'
    await wrapper.vm.changeUsersRole()

    expect(store.dispatch).toHaveBeenCalledWith('admin/changeTimesheetUsersRole', {
      users: [2],
      timesheetId: '9',
      role: 'user',
    })
    expect(awn.success).toHaveBeenCalledWith('User role have been updated.')
    expect(wrapper.vm.changeUsersRoleModalStatus).toBe(false)
  })

  it('updates filtered items from the super admin filter', () => {
    const { wrapper } = mountUsers()
    const filtered = [{ id: 3, email: 'filtered@example.com' }]

    wrapper.vm.superAdminFilterChanged(filtered)

    expect(wrapper.vm.filteredItems).toEqual(filtered)
  })
})
