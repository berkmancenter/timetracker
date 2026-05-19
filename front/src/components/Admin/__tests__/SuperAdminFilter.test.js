import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import SuperAdminFilter from '../SuperAdminFilter.vue'

const users = [
  { id: 1, email: 'user@example.com', roles: ['user'] },
  { id: 2, email: 'admin@example.com', roles: ['admin'] },
  { id: 3, email: 'both@example.com', roles: ['user', 'admin'] },
]

describe('SuperAdminFilter', () => {
  it('filters users by the active tab and emits changes', async () => {
    const wrapper = mount(SuperAdminFilter, {
      props: { users },
    })

    expect(wrapper.vm.filteredUsers.map((user) => user.id)).toEqual([1, 3])

    await wrapper.findAll('a')[1].trigger('click')
    expect(wrapper.vm.activeTab).toBe('admins')
    expect(wrapper.emitted('change')[0][0].map((user) => user.id)).toEqual([2, 3])

    await wrapper.findAll('a')[2].trigger('click')
    expect(wrapper.emitted('change')[1][0]).toEqual(users)
  })

  it('re-emits filtered users when the users prop changes', async () => {
    const wrapper = mount(SuperAdminFilter, {
      props: { users },
    })

    await wrapper.setProps({ users: [{ id: 4, roles: ['user'] }] })

    expect(wrapper.emitted('change')[0][0]).toEqual([{ id: 4, roles: ['user'] }])
  })
})
