import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import StatsFilters from '../StatsFilters.vue'

const periodStats = [
  {
    user_id: 1,
    email: 'ada@example.com',
    credits: 8,
    total_hours: 7,
    balance: -1,
    balance_percent: 87.5,
    last_entry_date: '2026-05-10',
    custom_field_4: 'Research',
  },
  {
    user_id: 2,
    email: 'grace@example.com',
    credits: 6,
    total_hours: 8,
    balance: 2,
    balance_percent: 133,
    last_entry_date: '2026-05-15',
    custom_field_4: 'Writing',
  },
]

function mountFilters() {
  return mount(StatsFilters, {
    props: {
      modelValue: true,
      customFields: [{ id: 4, title: 'Project', input_type: 'text' }],
      periodStats,
    },
    global: {
      stubs: {
        Modal: { template: '<div><slot /></div>' },
      },
    },
  })
}

describe('StatsFilters', () => {
  it('initializes custom field filters and maps input types', () => {
    const wrapper = mountFilters()

    expect(wrapper.vm.filterValues.customFields).toEqual({ 4: '' })
    expect(wrapper.vm.getInputType({ input_type: 'number' })).toBe('number')
    expect(wrapper.vm.getInputType({ input_type: 'text' })).toBe('text')
  })

  it('filters by identifier, numeric ranges, date range, and custom fields', () => {
    const wrapper = mountFilters()

    wrapper.vm.filterValues.identifier = 'ada'
    wrapper.vm.filterValues.minHours = '7'
    wrapper.vm.filterValues.maxTotalHours = '7'
    wrapper.vm.filterValues.maxBalance = '0'
    wrapper.vm.filterValues.minBalancePercent = '80'
    wrapper.vm.filterValues.maxLastEntryDate = '05/12/2026'
    wrapper.vm.filterValues.customFields[4] = 'research'
    wrapper.vm.applyFilters()

    expect(wrapper.emitted('filter-applied')[0][0]).toEqual([periodStats[0]])
    expect(wrapper.emitted('update:modelValue')[0][0]).toBe(false)
  })

  it('resets all filters', () => {
    const wrapper = mountFilters()
    wrapper.vm.filterValues.identifier = 'ada'
    wrapper.vm.filterValues.customFields[4] = 'Research'

    wrapper.vm.resetFilters()

    expect(wrapper.vm.filterValues.identifier).toBe('')
    expect(wrapper.vm.filterValues.customFields).toEqual({ 4: '' })
  })
})
