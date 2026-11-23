import dayjs from 'dayjs'
import { router } from '@/router/index'
import fetchIt from '@/lib/fetch-it'
import store2 from 'store2'

const apiUrl = import.meta.env.VITE_API_URL

// A function, so the default date is today also when the tab stays open over midnight
const defaultEntry = () => ({
  id: null,
  decimal_time: '',
  entry_date: dayjs().format('MMMM D, YYYY'),
  fields: {},
})

// The latest GET request for every fetch action, kept outside of the reactive state
const latestRequests = {}

const cancelledRequestError = () => {
  const error = new Error('Request was superseded by a newer request')
  error.name = 'AbortError'

  return error
}

const fetchJson = async (url, signal) => {
  const response = await fetchIt(url, {
    method: 'GET',
    signal,
  })

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }

  return await response.json()
}

const state = {
  timesheets: [],
  timesheetUsers: [],
  months: [],
  entries: [],
  entriesBeforeChange: false,
  selectedMonth: '',
  selectedTimesheet: {},
  formEntry: defaultEntry(),
  formMode: 'create',
  popular: {},
  periodTotals: [],
  periodTotalsMode: 'days',
  totalCurrentTimesheet: 0,
  totalCurrentMonth: 0,
  isPeriodView: false,
  period: {},
  periodUser: {},
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
    state.formEntry = defaultEntry()
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
  setPeriodView(state, isPeriodView) {
    state.isPeriodView = isPeriodView
  },
  setPeriod(state, period) {
    state.period = period
  },
  setPeriodUser(state, user) {
    state.periodUser = user
  },
}

const actions = {
  // Only the newest request of every kind is kept. Superseded and failed requests
  // reject, so their callers cannot apply data which belongs to another request.
  async fetchGet(context, options) {
    const name = options.methodName
    latestRequests[name]?.controller.abort()

    const request = { controller: new AbortController() }
    request.result = fetchJson(options.url, request.controller.signal).catch((error) => {
      if (request.controller.signal.aborted && latestRequests[name] !== request) {
        throw cancelledRequestError()
      }

      console.error(`${error} ${options.url}`)
      throw error
    })
    latestRequests[name] = request

    try {
      return await request.result
    } finally {
      if (latestRequests[name] === request) {
        delete latestRequests[name]
      }
    }
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
    let url = `${apiUrl}/time_entries/entries?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`
    if (context.state.isPeriodView) {
      url += `&period=${context.state.period.id}`
      url += `&user=${context.state.periodUser.id}`
    }

    return await context.dispatch('fetchGet', {
      url,
      methodName: 'fetchEntries',
    })
  },
  async fetchPopular(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/popular?timesheet_uuid=${context.state.selectedTimesheet.uuid}`,
      methodName: 'fetchPopular',
    })
  },
  async fetchPeriodTotals(context) {
    let url = `${apiUrl}/time_entries/days?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}&mode=${context.state.periodTotalsMode}`
    if (context.state.isPeriodView) {
      url += `&period=${context.state.period.id}`
      url += `&user=${context.state.periodUser.id}`
    }

    return await context.dispatch('fetchGet', {
      url,
      methodName: 'fetchPeriodTotals',
    })
  },
  async fetchTotals(context) {
    let url = `${apiUrl}/time_entries/totals?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`
    if (context.state.isPeriodView) {
      url += `&period=${context.state.period.id}`
      url += `&user=${context.state.periodUser.id}`
    }

    return await context.dispatch('fetchGet', {
      url,
      methodName: 'fetchTotals',
    })
  },
  async fetchAutoComplete(context, options) {
    const query = new URLSearchParams({
      field: options.field,
      term: options.term,
      timesheet_uuid: context.state.selectedTimesheet.uuid,
    })

    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/time_entries/auto_complete?${query}`,
      // Different fields have different result sets and must not cancel each other
      methodName: `fetchAutoComplete:${options.field}`,
    })
  },
  async fetchUsers(context) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/timesheets/${context.state.selectedTimesheet.id}/users`,
      methodName: 'fetchUsers',
    })
  },
  async fetchUser(context, userId) {
    return await context.dispatch('fetchGet', {
      url: `${apiUrl}/timesheets/${context.state.selectedTimesheet.id}/users/${userId}`,
      methodName: 'fetchUser',
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

    if (!response.ok) {
      throw new Error(`Saving the time entry failed (HTTP ${response.status})`)
    }

    return await response.json()
  },
  async deleteEntry(context, entry) {
    const response = await fetchIt(`${apiUrl}/time_entries/${entry.id}/delete`, {
      method: 'DELETE',
    })

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
  setPeriodUser(context, user) {
    context.commit('setPeriodUser', user)
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

    await Promise.all(itemsToReload.map(async (item) => {
      try {
        const data = await context.dispatch(`fetch${capitalize(item)}`)
        context.commit(`set${capitalize(item)}`, data)
      } catch (error) {
        // Keep the data which is already shown, fetchGet has logged the error
      }
    }))
  },
  async joinTimesheet(context, code) {
    const response = await fetchIt(`${apiUrl}/timesheets/join/${code}`, {
      method: 'POST',
    })

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
  setPeriodView(context, isPeriodView) {
    context.commit('setPeriodView', isPeriodView)
  },
  setPeriod(context, period) {
    context.commit('setPeriod', period)
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
