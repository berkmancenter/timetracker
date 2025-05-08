import dayjs from 'dayjs'
import { router } from '@/router/index'
import fetchIt from '@/lib/fetch-it'
import store2 from 'store2'

const apiUrl = import.meta.env.VITE_API_URL

const defaultEntry = {
  id: null,
  decimal_time: '',
  entry_date: dayjs().format('MMMM D, YYYY'),
  fields: {},
}

const state = {
  timesheets: [],
  timesheetUsers: [],
  months: [],
  entries: [],
  entriesBeforeChange: false,
  selectedMonth: '',
  selectedTimesheet: {},
  formEntry: JSON.parse(JSON.stringify(defaultEntry)),
  formMode: 'create',
  popular: {},
  periodTotals: [],
  periodTotalsMode: 'days',
  totalCurrentTimesheet: 0,
  totalCurrentMonth: 0,
  abortControllers: {},
}

const mutations = {
  setTimesheets(state, timesheets) {
    state.timesheets = timesheets
  },
  setMonths(state, months) {
    state.months = months
  },
  setEntries(state, entries) {
    state.entriesBeforeChange = true
    state.entries = entries

    setTimeout(() => {
      state.entriesBeforeChange = false
    }, 1)
  },
  setPopular(state, popular) {
    state.popular = popular
  },
  setPeriodTotals(state, periodTotals) {
    state.periodTotals = periodTotals
  },
  setTotals(state, totals) {
    state.totalCurrentTimesheet = totals.total_hours_current_timesheet
    state.totalCurrentMonth = totals.total_hours_current_month
  },
  addEntry(state, entry) {
    state.entries.push(entry)
  },
  deleteEntry(state, entry) {
    const index = state.entries.findIndex(entryInList => entryInList.id === entry.id);
    if (index !== -1) {
      state.entries.splice(index, 1)
    }
  },
  replaceEntry(state, entry) {
    state.entries = state.entries.map(obj => {
      if (obj.id === entry.id) {
        return entry
      } else {
        return obj
      }
    })
  },
  clearEntryForm(state) {
    state.formEntry = { ...JSON.parse(JSON.stringify(defaultEntry)) }
  },
  setFormField(state, data) {
    state.formEntry.fields[data.field] = data.value
  },
  setFormEntry(state, entry) {
    state.formEntry = entry
  },
  setFormMode(state, mode) {
    state.formMode = mode
  },
  setSelectedMonth(state, month) {
    state.selectedMonth = month
  },
  setSelectedTimesheet(state, timesheet) {
    state.selectedTimesheet = timesheet
  },
  setPeriodTotalsMode(state, mode) {
    state.periodTotalsMode = mode
  },
  setUsers(state, timesheetUsers) {
    state.timesheetUsers = timesheetUsers
  },
}

const actions = {
  async fetchGet(context, options) {
    if (context.state.abortControllers[options.methodName]) {
      context.state.abortControllers[options.methodName].abort()
    }

    context.state.abortControllers[options.methodName] = new AbortController()

    let response
    try {
      response = await fetchIt(options.url, {
        method: 'GET',
        signal: context.state.abortControllers[options.methodName].signal,
      })
    } catch (error) {
      if (error.includes('aborted') === false) {
        console.error(`${error} ${options.url}`)
      }

      return []
    }

    const data = await response.json()

    return data
  },
  async fetchMonths(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/months?timesheet_uuid=${context.state.selectedTimesheet.uuid}`,
      methodName: 'fetchMonths',
    })
  },
  async fetchTimesheets(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/timesheets`,
      methodName: 'fetchTimesheets',
    })
  },
  async fetchEntries(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/entries?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`,
      methodName: 'fetchEntries',
    })
  },
  async fetchPopular(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/popular`,
      methodName: 'fetchPopular',
    })
  },
  async fetchPeriodTotals(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/days?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}&mode=${context.state.periodTotalsMode}`,
      methodName: 'fetchPeriodTotals',
    })
  },
  async fetchTotals(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/totals?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`,
      methodName: 'fetchTotals',
    })
  },
  async fetchAutoComplete(context, options) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/auto_complete?field=${options.field}&term=${options.term}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`,
      methodName: 'fetchAutoComplete',
    })
  },
  async fetchUsers(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/timesheets/${context.state.selectedTimesheet.id}/users`,
      methodName: 'fetchUsers',
    })
  },
  async submitEntryForm(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/edit`, {
      method: 'POST',
      body: JSON.stringify({
        time_entry: context.state.formEntry,
        timesheet_uuid: context.state.selectedTimesheet.uuid,
      }),
    })
    const data = response.json()

    return data
  },
  async deleteEntry(context, entry) {
    const response = await fetchIt(`${apiUrl}/time_entries/${entry.id}/delete`)

    if (response.ok) {
      context.commit('deleteEntry', entry)
    }

    return response
  },
  addEntry(context, entry) {
    const month = router.currentRoute._value.params?.month

    if (month !== 'all' && entry.entry_date.includes(month) === false) {
      return
    }

    context.commit('addEntry', entry)
  },
  replaceEntry(context, entry) {
    context.commit('replaceEntry', entry)
  },
  clearEntryForm(context) {
    context.commit('clearEntryForm')
    context.commit('setFormMode', 'create')
  },
  setFormField(context, data) {
    context.commit('setFormField', data)
  },
  setFormEntry(context, entry) {
    context.commit('setFormEntry', entry)
  },
  setFormMode(context, mode) {
    context.commit('setFormMode', mode)
  },
  setMonths(context, months) {
    context.commit('setMonths', months)
  },
  setUsers(context, timesheetUsers) {
    context.commit('setUsers', timesheetUsers)
  },
  setSelectedMonthFromRoute(context) {
    const currentMonthParam = router.currentRoute._value.params?.month
    if ((currentMonthParam && context.state.months.includes(currentMonthParam)) || currentMonthParam === 'all') {
      context.dispatch('setSelectedMonth', currentMonthParam)
    } else {
      if (context.state.months.length > 0) {
        context.dispatch('setSelectedMonth', context.state.months[0])
      } else {
        context.dispatch('setSelectedMonth', 'all')
      }
    }
  },
  setTimesheets(context, timesheets) {
    context.commit('setTimesheets', timesheets)
  },
  setSelectedTimesheetFromRoute(context) {
    const currentTimesheetParam = router.currentRoute._value.params?.timesheet
    let timesheetFromRouteLocalStorage = context.state.timesheets.find(timesheet => timesheet.uuid === currentTimesheetParam)

    if (!timesheetFromRouteLocalStorage) {
      if (store2('timetracker.active_timesheet') !== null) {
        timesheetFromRouteLocalStorage = context.state.timesheets.find(timesheet => timesheet.uuid === store2('timetracker.active_timesheet'))
      }
    }

    if (timesheetFromRouteLocalStorage) {
      context.dispatch('setSelectedTimesheet', timesheetFromRouteLocalStorage)
    } else {
      if (context.state.timesheets.length > 0) {
        context.dispatch('setSelectedTimesheet', context.state.timesheets[0])
      }
    }
  },
  setSelectedMonth(context, month) {
    context.commit('setSelectedMonth', month)
  },
  setSelectedTimesheet(context, timesheet) {
    store2('timetracker.active_timesheet', timesheet.uuid)
    context.commit('setSelectedTimesheet', timesheet)
  },
  async reloadViewData(context, itemsToReload = ['months', 'popular', 'entries', 'periodTotals', 'totals']) {
    const capitalize = s => (s && s[0].toUpperCase() + s.slice(1)) || ''
    const promises = []

    for (const item of itemsToReload) {
      const promise = (async () => {
        const fetchMethodName = `fetch${capitalize(item)}`

        const data = await context.dispatch(fetchMethodName)
        context.commit(`set${capitalize(item)}`, data)
      })()

      promises.push(promise)
    }

    return await Promise.all(promises)
  },
  async joinTimesheet(context, code) {
    const response = await fetchIt(`${apiUrl}/timesheets/join/${code}`)

    return response
  },
  setPeriodTotalsMode(context, mode) {
    context.commit('setPeriodTotalsMode', mode)
    context.dispatch('reloadViewData', ['periodTotals'])
  },
  updateAllTimesheetUserSelection(context, isSelected) {
    context.commit('setUsers', context.state.timesheetUsers.map(user => ({
      ...user,
      selected: isSelected,
    })))
  },
  selectAllTimesheetUsers(context) {
    context.dispatch('updateAllTimesheetUserSelection', true)
  },
  deselectAllTimesheetUsers(context) {
    context.dispatch('updateAllTimesheetUserSelection', false)
  },
  selectTimesheetUsers(context, userIds) {
    context.commit('setUsers', context.state.timesheetUsers.map(user => ({
      ...user,
      selected: userIds.includes(user.id),
    })))
  },
  async sudoUsersTimesheet(context, data) {
    const response = await fetchIt(`${apiUrl}/users/sudo`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: data.users,
        timesheet_id: data.timesheetId,
      }),
    })

    return response
  },
  async unsudoUsersTimesheet(context) {
    const response = await fetchIt(`${apiUrl}/users/unsudo`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: [],
      }),
    })

    return response
  },
}

const getters = {}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}
