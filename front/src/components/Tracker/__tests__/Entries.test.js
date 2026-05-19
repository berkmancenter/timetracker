import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  redirectToSelectedMonth: vi.fn(),
  hideAllPoppers: vi.fn(),
}))

vi.mock('@/router/index', () => ({
  redirectToSelectedMonth: mocks.redirectToSelectedMonth,
}))

vi.mock('floating-vue', () => ({
  hideAllPoppers: mocks.hideAllPoppers,
}))

import Entries from '../Entries.vue'

function createStore(overrides = {}) {
  const state = {
    shared: {
      user: {
        user_id: 10,
        sudoMode: false,
        sudo_users: [10, 11],
      },
    },
    tracker: {
      selectedTimesheet: {
        id: 1,
        uuid: 'alpha',
        roles: ['admin'],
        custom_fields: [
          { title: 'Project', machine_name: 'project', list: true },
          { title: 'Description', machine_name: 'description', list: false },
        ],
      },
      entries: [
        {
          id: 1,
          user_id: 10,
          entry_date: '2026-05-18',
          decimal_time: '2.5',
          email: 'ada@example.com',
          fields: { project: 'Research', description: 'Notes' },
        },
        {
          id: 2,
          user_id: 11,
          entry_date: '2026-05-19',
          decimal_time: '1',
          email: 'grace@example.com',
          fields: { project: 'Writing' },
        },
      ],
      entriesBeforeChange: false,
      selectedMonth: '2026-05',
      months: ['2026-04', '2026-05', '2026-06'],
      timesheetUsers: [
        { id: 2, email: 'zeta@example.com', selected: false },
        { id: 1, email: 'alpha@example.com', selected: true },
      ],
      isPeriodView: false,
    },
  }

  Object.assign(state.shared.user, overrides.user)
  Object.assign(state.tracker, overrides.tracker)

  const dispatch = vi.fn(async (action) => {
    if (action === 'tracker/deleteEntry') return { ok: true }
    if (action === 'tracker/fetchMonths') return ['2026-05']
    if (action === 'tracker/unsudoUsersTimesheet') return { ok: true }
    if (action === 'shared/fetchUser') return { user_id: 10, sudoMode: false }
    if (action === 'tracker/sudoUsersTimesheet') return { ok: true }
    return undefined
  })

  const commit = vi.fn((mutation, value) => {
    if (mutation === 'tracker/setSelectedMonth') {
      state.tracker.selectedMonth = value
    }
  })

  return { state, dispatch, commit }
}

function mountEntries(store = createStore(), props = {}) {
  const push = vi.fn()
  const emit = vi.fn()
  const warning = vi.fn()
  const wrapper = mount(Entries, {
    props,
    global: {
      mocks: {
        $store: store,
        $router: { push },
        mitt: { emit },
        awn: { warning },
      },
      stubs: {
        ActionButton: {
          props: ['buttonText', 'disabled'],
          template: '<button class="action-button-stub" :disabled="disabled" @click="$emit(\'click\')">{{ buttonText }}</button>',
        },
        Icon: {
          props: ['src'],
          template: '<img class="icon-stub" :src="src">',
        },
        Modal: {
          template: '<div class="modal-stub"><slot /></div>',
        },
        VDropdown: {
          template: '<div class="dropdown-stub"><slot /><slot name="popper" /></div>',
          methods: {
            show: vi.fn(),
            hide: vi.fn(),
          },
        },
        TransitionGroup: {
          template: '<div><slot /></div>',
        },
      },
      directives: {
        closePopper: {},
      },
    },
  })

  return { wrapper, store, push, emit, warning }
}

describe('Entries', () => {
  it('groups entries by descending date and renders listed fields', () => {
    const { wrapper } = mountEntries()

    expect(Object.keys(wrapper.vm.entriesByDate)).toEqual(['2026-05-19', '2026-05-18'])
    expect(wrapper.text()).toContain('Project')
    expect(wrapper.text()).toContain('Research')
    expect(wrapper.text()).toContain('Writing')
    expect(wrapper.text()).toContain('2.5')
  })

  it('hides navigation controls in periods view', () => {
    const { wrapper } = mountEntries(createStore(), { periodsView: true })

    expect(wrapper.find('.tracker-entries-navigation').exists()).toBe(false)
  })

  it('opens the entry form from the add button', async () => {
    const { wrapper, emit } = mountEntries()

    await wrapper.findAll('.action-button-stub')[0].trigger('click')

    expect(emit).toHaveBeenCalledWith('addEntry')
  })

  it('sets edit and clone entries into the form', () => {
    const { wrapper, store, emit } = mountEntries()
    const entry = store.state.tracker.entries[0]

    wrapper.vm.editEntry(entry)
    expect(mocks.hideAllPoppers).toHaveBeenCalled()
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setFormMode', 'edit')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setFormEntry', expect.objectContaining({ id: 1, entry_date: 'May 18, 2026' }))
    expect(emit).toHaveBeenCalledWith('editEntry')

    wrapper.vm.cloneEntry(entry)
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setFormMode', 'create')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setFormEntry', expect.objectContaining({ id: null }))
    expect(emit).toHaveBeenCalledWith('cloneEntry')
  })

  it('confirms and deletes an entry', async () => {
    const { wrapper, store, emit } = mountEntries()
    const entry = store.state.tracker.entries[0]

    wrapper.vm.deleteEntryConfirm(entry)
    expect(wrapper.vm.deleteEntryModalStatus).toBe(true)
    expect(wrapper.vm.deleteEntryCurrent).toMatchObject(entry)

    await wrapper.vm.deleteEntry()

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/deleteEntry', entry)
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setMonths', ['2026-05'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['popular', 'periodTotals', 'totals'])
    expect(mocks.redirectToSelectedMonth).toHaveBeenCalledWith(store)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.deleteEntryModalStatus).toBe(false)
  })

  it('navigates between months only when a target month exists', async () => {
    const { wrapper, store, push, emit } = mountEntries()

    expect(wrapper.vm.hasPreviousMonth()).toBe(true)
    expect(wrapper.vm.hasNextMonth()).toBe(true)

    await wrapper.vm.redirectToPreviousMonth()

    expect(store.commit).toHaveBeenCalledWith('tracker/setSelectedMonth', '2026-04')
    expect(push).toHaveBeenCalledWith({ name: 'tracker.index', params: { timesheet: 'alpha', month: '2026-04' } })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'])
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('changes selected month from the month selector', async () => {
    const { wrapper, store, push } = mountEntries()
    wrapper.vm.selectMonthModalStatus = true

    await wrapper.vm.changeMonth('2026-06')

    expect(store.commit).toHaveBeenCalledWith('tracker/setSelectedMonth', '2026-06')
    expect(push).toHaveBeenCalledWith({ name: 'tracker.index', params: { timesheet: 'alpha', month: '2026-06' } })
    expect(wrapper.vm.selectMonthModalStatus).toBe(false)
  })

  it('renders sudo state and can return to the current user', async () => {
    const store = createStore({ user: { sudoMode: true } })
    const { wrapper } = mountEntries(store)

    expect(wrapper.text()).toContain('You are viewing time entries of other users.')
    expect(wrapper.text()).toContain('Email')
    expect(wrapper.text()).toContain('ada@example.com')

    await wrapper.vm.unSudo()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/unsudoUsersTimesheet')
    expect(store.dispatch).toHaveBeenCalledWith('shared/setUser', { user_id: 10, sudoMode: false })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['popular', 'periodTotals', 'totals', 'entries'])
  })

  it('selects users and submits sudo user selection', async () => {
    const { wrapper, store } = mountEntries()
    const user = store.state.tracker.timesheetUsers[0]

    expect(wrapper.vm.timesheetUsers.map((item) => item.email)).toEqual(['alpha@example.com', 'zeta@example.com'])

    wrapper.vm.selectTimesheetUser(user)
    expect(user.selected).toBe(true)

    wrapper.vm.selectAllUsers()
    wrapper.vm.deselectAllUsers()
    wrapper.vm.openUsersSelector()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/selectAllTimesheetUsers')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/deselectAllTimesheetUsers')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/selectTimesheetUsers', [10, 11])
    expect(wrapper.vm.selectUsersModalStatus).toBe(true)

    await wrapper.vm.setTimesheetUsers()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/sudoUsersTimesheet', { users: [2, 1], timesheetId: 1 })
    expect(store.dispatch).toHaveBeenCalledWith('shared/fetchUser')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['months'])
    expect(wrapper.vm.selectUsersModalStatus).toBe(false)
  })

  it('updates hover and menu state', () => {
    const { wrapper, store } = mountEntries()
    const entry = store.state.tracker.entries[0]

    wrapper.vm.enterEntry(entry)
    expect(entry.active).toBe(true)

    wrapper.vm.leaveEntry(entry)
    expect(entry.active).toBe(false)

    entry.menuOpen = true
    wrapper.vm.enterEntry(entry)
    wrapper.vm.leaveEntry(entry)
    expect(entry.active).toBe(true)

    wrapper.vm.closeMenu(entry)
    expect(entry.active).toBe(false)
    expect(entry.menuOpen).toBe(false)
  })
})
