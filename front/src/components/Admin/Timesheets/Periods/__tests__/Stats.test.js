import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Stats from '../Stats.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore() {
  const state = {
    admin: {
      timesheet: { id: 9, uuid: 'alpha', name: 'Alpha' },
      periodStats: {
        period: {
          id: 2,
          name: 'Spring',
          from: '2026-05-01',
          to: '2026-05-31',
          custom_fields: [{ id: 4, title: 'Project' }],
        },
        stats: [
          {
            user_id: 1,
            email: 'ada@example.com',
            credits: 8,
            total_hours: 7,
            should_hours: 8,
            balance: -1,
            balance_percent: 87.5,
            last_entry_date: '2026-05-10',
            custom_field_4: 'Research',
            roles: ['user'],
          },
        ],
      },
    },
  }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchPeriodStats') return state.admin.periodStats
    if (action === 'admin/fetchTimesheet') return state.admin.timesheet
    return undefined
  })

  return { state, dispatch }
}

function mountStats(store = createStore()) {
  const push = vi.fn()
  const emit = vi.fn()
  const wrapper = mount(Stats, {
    global: {
      mocks: {
        $store: store,
        $route: { params: { timesheet_id: '9', id: '2' } },
        $router: { push },
        mitt: { emit },
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        ActionButton: { props: ['buttonText'], template: '<button @click="$emit(\'click\')">{{ buttonText }}</button>' },
        SuperAdminFilter: { props: ['users'], template: '<div class="filter-stub" />' },
        AdminTable: { template: '<table><slot /></table>' },
        FilterModal: { template: '<div class="filter-modal-stub" />' },
      },
    },
  })

  return { wrapper, store, push, emit }
}

describe('Admin Period Stats', () => {
  it('loads stats and renders period context', async () => {
    const { wrapper, store, emit } = mountStats()

    await flushPromises()
    wrapper.vm.superAdminFilterChanged(store.state.admin.periodStats.stats)
    await wrapper.vm.$nextTick()

    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchPeriodStats', { periodId: '2', timesheetId: '9' })
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/setPeriodStats', store.state.admin.periodStats)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.text()).toContain('Spring')
    expect(wrapper.text()).toContain('Research')
  })

  it('formats and reads stat fields', () => {
    const { wrapper } = mountStats()
    const stat = wrapper.vm.$store.state.admin.periodStats.stats[0]

    expect(wrapper.vm.formatLastEntryDate('2026-05-10')).toBe('05/10/2026')
    expect(wrapper.vm.formatLastEntryDate(null)).toBe('')
    expect(wrapper.vm.getCustomFieldValue(stat, { id: 4 })).toBe('Research')
  })

  it('opens tracker period user route and applies filters', () => {
    const { wrapper, push } = mountStats()
    const stat = wrapper.vm.$store.state.admin.periodStats.stats[0]
    const filtered = [stat]

    wrapper.vm.openPeriodUserInTracker(stat)
    expect(push).toHaveBeenCalledWith({
      name: 'tracker.period.user',
      params: { period_id: '2', timesheet: 'alpha', user_id: 1 },
    })

    wrapper.vm.openFilterModal()
    expect(wrapper.vm.showFilterModal).toBe(true)

    wrapper.vm.applyFilters(filtered)
    expect(wrapper.vm.filteredItems).toEqual(filtered)
  })
})
