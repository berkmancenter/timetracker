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
        Icon: true,
      },
    },
  })

  return { wrapper, emit, awn, store }
}

describe('Admin Timesheet Users', () => {
  it('loads users and timesheet data without dead checkboxes or hidden templates', async () => {
    const { wrapper, store, emit } = mountUsers()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheetUsers', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '9')
    expect(wrapper.vm.users).toEqual(store.users)
    expect(wrapper.vm.filteredItems).toEqual(store.users)
    expect(wrapper.vm.timesheet).toEqual(store.timesheet)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.breadcrumbs.map((crumb) => crumb.text)).toEqual(['Timesheets', 'Alpha', 'Users'])
    expect(wrapper.find('input[type="checkbox"]').exists()).toBe(false)
    expect(wrapper.find('.admin-timesheet-users-set-role').exists()).toBe(false)
  })

  it('sorts users by email and joined date', async () => {
    const { wrapper } = mountUsers()
    await flushPromises()

    const headers = wrapper.findAll('th.admin-table-sortable')
    await headers[0].trigger('click')
    expect(wrapper.vm.sortedItems.map((u) => u.email)).toEqual(['ada@example.com', 'grace@example.com'])

    await headers[0].trigger('click')
    expect(wrapper.vm.sortedItems.map((u) => u.email)).toEqual(['grace@example.com', 'ada@example.com'])

    await headers[1].trigger('click')
    expect(wrapper.vm.sortedItems.map((u) => u.id)).toEqual([1, 2])
    await headers[1].trigger('click')
    expect(wrapper.vm.sortedItems.map((u) => u.id)).toEqual([2, 1])
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

  it('pre-selects current role and changes a user role', async () => {
    const { wrapper, store, awn } = mountUsers()
    await flushPromises()

    wrapper.vm.changeUsersRoleModalOpen(store.users[0])
    expect(wrapper.vm.changeUsersRoleSelected).toBe('user')

    wrapper.vm.changeUsersRoleModalOpen(store.users[1])
    expect(wrapper.vm.changeUsersRoleSelected).toBe('admin')
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
