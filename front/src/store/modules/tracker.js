import dayjs from 'dayjs'
import { router } from '@/router/index'
import fetchIt from '@/lib/fetch-it'

const apiUrl = import.meta.env.VITE_API_URL

const defaultEntry = {
  id: null,
  category: '',
  project: '',
  description: '',
  decimal_time: '',
  entry_date: dayjs().format('MMMM D, YYYY'),
}

const state = {
  timesheets: [],
  months: [],
  entries: [],
  selectedMonth: 'all',
  selectedTimesheet: {},
  formEntry: JSON.parse(JSON.stringify(defaultEntry)),
  formMode: 'create',
  popular: {
    categories: [],
    projects: [],
  },
  dailyTotals: [],
}

const mutations = {
  setTimesheets(state, timesheets) {
    state.timesheets = timesheets
  },
  setMonths(state, months) {
    state.months = months
  },
  setEntries(state, entries) {
    state.entries = entries
  },
  setPopular(state, popular) {
    state.popular = popular
  },
  setDailyTotals(state, dailyTotals) {
    state.dailyTotals = dailyTotals
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
    Object.assign(state.formEntry, defaultEntry)
  },
  setFormField(state, data) {
    state.formEntry[data.field] = data.value
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
}

const actions = {
  async fetchMonths(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/months?timesheet_uuid=${context.state.selectedTimesheet.uuid}`)
    const data = await response.json()

    return data
  },
  async fetchTimesheets(context) {
    const response = await fetchIt(`${apiUrl}/timesheets`)
    const data = await response.json()

    return data
  },
  async fetchEntries(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/entries?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`)
    const data = await response.json()

    return data
  },
  async fetchPopular(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/popular`)
    const data = await response.json()

    return data
  },
  async fetchDailyTotals(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/days?month=${context.state.selectedMonth}&timesheet_uuid=${context.state.selectedTimesheet.uuid}`)
    const data = await response.json()

    return data
  },
  async fetchAutoComplete(context, options) {
    const response = await fetchIt(`${apiUrl}/time_entries/auto_complete?field=${options.field}&term=${options.term}`)
    const data = await response.json()

    return data
  },
  async submitEntryForm(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/edit`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
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

    const currentMonthParam = router.currentRoute._value.params?.month
    if ((currentMonthParam && months.includes(currentMonthParam)) || currentMonthParam === 'all') {
      context.dispatch('setSelectedMonth', currentMonthParam)
    } else {
      if (months.length > 0) {
        context.dispatch('setSelectedMonth', months[0])
      } else {
        context.dispatch('setSelectedMonth', 'all')
      }

      context.dispatch('reloadViewData', ['entries', 'dailyTotals'])
    }
  },
  setTimesheets(context, timesheets) {
    context.commit('setTimesheets', timesheets)

    const currentTimesheetParam = router.currentRoute._value.params?.timesheet
    const timesheetFromRoute = timesheets.find(timesheet => timesheet.uuid === currentTimesheetParam)
    if (timesheetFromRoute) {
      context.dispatch('setSelectedTimesheet', timesheetFromRoute)
    } else {
      if (timesheets.length > 0) {
        context.dispatch('setSelectedTimesheet', timesheets[0])
      }
    }
  },
  setSelectedMonth(context, month) {
    context.commit('setSelectedMonth', month)
  },
  setSelectedTimesheet(context, timesheet) {
    context.commit('setSelectedTimesheet', timesheet)
  },
  async reloadViewData(context, itemsToReload = ['months', 'popular', 'entries', 'dailyTotals']) {
    const capitalize = s => (s && s[0].toUpperCase() + s.slice(1)) || ''
    const promises = []

    for (const item of itemsToReload) {
      const promise = (async () => {
        const data = await context.dispatch(`fetch${capitalize(item)}`)
        context.commit(`set${capitalize(item)}`, data)
      })()

      promises.push(promise)
    }
  
    return await Promise.all(promises)
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
