import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Credits from '../Credits.vue'

const flushPromises = () => new Promise((resolve) => setTimeout(resolve))

function createStore(response = { ok: true }) {
  const state = {
    admin: {
      timesheet: { id: 9, name: 'Alpha' },
      periodCredits: {
        period: {
          id: 2,
          name: 'Spring',
          from: '2026-05-01',
          to: '2026-05-31',
          custom_fields: [{ id: 4, title: 'Project', input_type: 'text' }],
        },
        credits: [
          { user_id: 1, email: 'ada@example.com', credit_amount: 8, selected: false },
          { user_id: 2, email: 'grace@example.com', credit_amount: 6, selected: true, custom_field_4: 'Writing' },
        ],
      },
    },
  }
  const dispatch = vi.fn(async (action) => {
    if (action === 'admin/fetchPeriodCredits') return state.admin.periodCredits
    if (action === 'admin/fetchTimesheet') return state.admin.timesheet
    if (action === 'admin/savePeriodCredits') return response
    return undefined
  })

  return { state, dispatch }
}

function mountCredits(store = createStore()) {
  const emit = vi.fn()
  const awn = { success: vi.fn(), warning: vi.fn() }
  const wrapper = mount(Credits, {
    global: {
      mocks: {
        $store: store,
        $route: { params: { timesheet_id: '9', id: '2' } },
        mitt: { emit },
        awn,
      },
      stubs: {
        Breadcrumbs: { props: ['crumbs'], template: '<nav>{{ crumbs.map(c => c.text).join(" / ") }}</nav>' },
        ActionButton: { props: ['buttonText', 'disabled'], template: '<button :disabled="disabled" @click="$emit(\'click\')">{{ buttonText }}</button>' },
        SuperAdminFilter: { props: ['users'], template: '<div class="filter-stub" />' },
        AdminTable: { template: '<table><slot /></table>' },
        Modal: { template: '<div><slot /></div>' },
      },
    },
  })

  return { wrapper, store, emit, awn }
}

describe('Admin Period Credits', () => {
  it('loads credits, timesheet, and initializes missing custom field values', async () => {
    const { wrapper, store, emit } = mountCredits()

    await flushPromises()

    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchPeriodCredits', { periodId: '2', timesheetId: '9' })
    expect(store.dispatch).toHaveBeenCalledWith('admin/fetchTimesheet', '9')
    expect(store.dispatch).toHaveBeenCalledWith('admin/setPeriodCredits', store.state.admin.periodCredits)
    expect(store.state.admin.periodCredits.credits[0].custom_field_4).toBe('')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.customFields).toEqual([{ id: 4, title: 'Project', input_type: 'text' }])
  })

  it('toggles all credits and updates custom field values', async () => {
    const { wrapper, store } = mountCredits()
    await flushPromises()

    wrapper.vm.$refs.toggleAllCheckbox.checked = true
    wrapper.vm.toggleAll()
    expect(store.state.admin.periodCredits.credits.every((credit) => credit.selected)).toBe(true)

    wrapper.vm.updateCustomFieldValue(store.state.admin.periodCredits.credits[0], { id: 4 }, 'Research')
    expect(store.state.admin.periodCredits.credits[0].custom_field_4).toBe('Research')
  })

  it('saves all visible credits', async () => {
    const { wrapper, store, awn } = mountCredits()
    await flushPromises()
    wrapper.vm.filteredItems = store.state.admin.periodCredits.credits

    await wrapper.vm.saveCreditsAll()

    expect(store.dispatch).toHaveBeenCalledWith('admin/savePeriodCredits', {
      periodId: '2',
      timesheetId: '9',
      credits: store.state.admin.periodCredits.credits,
    })
    expect(awn.success).toHaveBeenCalledWith('Hours have been saved.')
    expect(wrapper.vm.saveAllDisabled).toBe(false)
  })

  it('requires selected credits before opening the selected-save modal', async () => {
    const { wrapper, awn } = mountCredits()
    await flushPromises()
    wrapper.vm.filteredItems = [{ selected: false }]

    wrapper.vm.saveCreditsSelectedModalOpen()

    expect(awn.warning).toHaveBeenCalledWith('No records selected.')
    expect(wrapper.vm.periodCreditsSelectedSetModalStatus).toBe(false)
  })

  it('sets hours and saves selected credits', async () => {
    const { wrapper, store, awn } = mountCredits()
    await flushPromises()
    const selected = store.state.admin.periodCredits.credits.filter((credit) => credit.selected)
    wrapper.vm.filteredItems = store.state.admin.periodCredits.credits
    wrapper.vm.creditHours = 10

    wrapper.vm.saveCreditsSelectedModalOpen()
    expect(wrapper.vm.periodCreditsSelectedSetModalStatus).toBe(true)

    await wrapper.vm.saveCreditsSelected()

    expect(selected[0].credit_amount).toBe(10)
    expect(store.dispatch).toHaveBeenCalledWith('admin/savePeriodCredits', {
      periodId: '2',
      timesheetId: '9',
      credits: selected,
    })
    expect(awn.success).toHaveBeenCalledWith('Hours have been saved.')
    expect(wrapper.vm.periodCreditsSelectedSetModalStatus).toBe(false)
  })
})
