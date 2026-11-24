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

  it('finds users by the name shown in the stats table', () => {
    const wrapper = mount(StatsFilters, {
      props: {
        modelValue: true,
        periodStats: [
          { user_id: 1, first_name: 'Ada', last_name: 'Lovelace', email: 'al@example.com' },
          { user_id: 2, first_name: 'Grace', last_name: 'Hopper', email: 'gh@example.com' },
        ],
      },
      global: {
        stubs: {
          Modal: { template: '<div><slot /></div>' },
        },
      },
    })

    wrapper.vm.filterValues.identifier = 'lovelace'
    wrapper.vm.applyFilters()

    expect(wrapper.emitted('filter-applied')[0][0].map(item => item.user_id)).toEqual([1])
  })

  it('resets all filters', () => {
    const wrapper = mountFilters()
    wrapper.vm.filterValues.identifier = 'ada'
    wrapper.vm.filterValues.customFields[4] = 'Research'

    wrapper.vm.resetFilters()

    expect(wrapper.vm.filterValues.identifier).toBe('')
    expect(wrapper.vm.filterValues.customFields).toEqual({ 4: '' })
  })

  it('excludes rows without last_entry_date when a date filter is set', () => {
    const wrapper = mount(StatsFilters, {
      props: {
        modelValue: true,
        periodStats: [
          ...periodStats,
          { user_id: 3, email: 'nobody@example.com', last_entry_date: null },
        ],
      },
      global: {
        stubs: {
          Modal: { template: '<div><slot /></div>' },
        },
      },
    })

    wrapper.vm.filterValues.minLastEntryDate = '05/01/2026'
    wrapper.vm.applyFilters()

    expect(wrapper.emitted('filter-applied')[0][0].map((item) => item.user_id)).toEqual([1, 2])
  })

  it('handles unpadded dates consistently in time zones west of UTC', () => {
    const timeZone = process.env.TZ
    process.env.TZ = 'America/New_York'

    try {
      const wrapper = mountFilters()
      wrapper.vm.filterValues.minLastEntryDate = '5/10/2026'
      wrapper.vm.filterValues.maxLastEntryDate = '5/10/2026'
      wrapper.vm.applyFilters()

      expect(wrapper.emitted('filter-applied')[0][0].map((item) => item.user_id)).toEqual([1])
    } finally {
      process.env.TZ = timeZone
    }
  })

  it('initializes custom field filters when customFields prop arrives later', async () => {
    const wrapper = mount(StatsFilters, {
      props: {
        modelValue: true,
        customFields: [],
        periodStats,
      },
      global: {
        stubs: {
          Modal: { template: '<div><slot /></div>' },
        },
      },
    })

    await wrapper.setProps({ customFields: [{ id: 9, title: 'Department', input_type: 'text' }] })

    expect(wrapper.vm.filterValues.customFields).toEqual({ 9: '' })
  })
})
