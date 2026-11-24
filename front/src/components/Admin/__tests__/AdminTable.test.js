import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import AdminTable from '../AdminTable.vue'

describe('AdminTable', () => {
  it('renders table content inside a scrollable wrapper with custom classes', () => {
    const wrapper = mount(AdminTable, {
      props: {
        tableClasses: ['extra-table-class'],
      },
      slots: {
        default: '<thead><tr><th>Name</th></tr></thead><tbody><tr><td>Alpha</td></tr></tbody>',
      },
    })

    expect(wrapper.find('.admin-table-wrapper').exists()).toBe(true)
    expect(wrapper.find('table').classes()).toContain('admin-table')
    expect(wrapper.find('table').classes()).toContain('extra-table-class')
    expect(wrapper.text()).toContain('Alpha')
  })

  it('uses a fresh default array for tableClasses per instance', () => {
    const first = AdminTable.props.tableClasses.default()
    const second = AdminTable.props.tableClasses.default()

    expect(first).toEqual([])
    expect(first).not.toBe(second)
  })
})
