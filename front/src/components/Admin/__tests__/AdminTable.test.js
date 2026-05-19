import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  tablesort: vi.fn(),
  extend: vi.fn(),
}))

vi.mock('tablesort', () => {
  mocks.tablesort.extend = mocks.extend
  return { default: mocks.tablesort }
})

import AdminTable from '../AdminTable.vue'

describe('AdminTable', () => {
  it('renders table content and initializes sorting', () => {
    const wrapper = mount(AdminTable, {
      props: {
        tableClasses: ['extra-table-class'],
      },
      slots: {
        default: '<thead><tr><th>Name</th></tr></thead><tbody><tr><td>Alpha</td></tr></tbody>',
      },
    })

    expect(wrapper.find('table').classes()).toContain('extra-table-class')
    expect(wrapper.text()).toContain('Alpha')
    expect(mocks.extend).toHaveBeenCalledWith('number', expect.any(Function), expect.any(Function))
    expect(mocks.tablesort).toHaveBeenCalledWith(wrapper.vm.$refs.adminTable, { descending: true })
  })

  it('refreshes sorting when forced', async () => {
    const wrapper = mount(AdminTable, {
      props: {
        forceSortingRefresh: ['a'],
      },
      slots: {
        default: '<thead><tr><th>Name</th></tr></thead>',
      },
    })

    mocks.tablesort.mockClear()
    await wrapper.setProps({ forceSortingRefresh: ['b'] })
    await wrapper.vm.$nextTick()

    expect(mocks.tablesort).toHaveBeenCalledWith(wrapper.vm.$refs.adminTable, { descending: true })
  })
})
