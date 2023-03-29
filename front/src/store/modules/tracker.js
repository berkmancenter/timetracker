import dayjs from 'dayjs'

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
  months: [],
  entries: [],
  selectedMonth: 'all',
  formEntry: JSON.parse(JSON.stringify(defaultEntry)),
  formMode: 'create',
  user: {
    username: '',
  },
  popular: {
    categories: [],
    projects: [],
  },
  dailyTotals: [],
}

const mutations = {
  setMonths(state, months) {
    state.months = months
  },
  setEntries(state, entries) {
    state.entries = entries
  },
  setUser(state, user) {
    state.user = user
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
  setMonths(state, months) {
    state.months = months
  },
}

const actions = {
  async fetchMonths(context) {
    const response = await fetch(`${apiUrl}/time_entries/months`)
    const data = await response.json()

    return data
  },
  async fetchEntries(context) {
    const response = await fetch(`${apiUrl}/time_entries/entries?month=${context.state.selectedMonth}`)
    const data = await response.json()
    context.commit('setEntries', data.entries)

    return data
  },
  async fetchUser(context) {
    const response = await fetch(`${apiUrl}/users/current_user`)
    const data = await response.json()
    context.commit('setUser', data)

    return data
  },
  async fetchPopular(context) {
    const response = await fetch(`${apiUrl}/time_entries/popular`)
    const data = await response.json()
    context.commit('setPopular', data)

    return data
  },
  async fetchDailyTotals(context) {
    const response = await fetch(`${apiUrl}/time_entries/days?month=${context.state.selectedMonth}`)
    const data = await response.json()
    context.commit('setDailyTotals', data)

    return data
  },
  async fetchAutoComplete(context, options) {
    const response = await fetch(`${apiUrl}/time_entries/auto_complete?field=${options.field}&term=${options.term}`)
    const data = await response.json()

    return data
  },
  async submitEntryForm(context) {
    const response = await fetch(`${apiUrl}/time_entries/edit`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ time_entry: context.state.formEntry }),
    })
    const data = response.json()

    return data
  },
  async deleteEntry(context, entry) {
    const response = await fetch(`${apiUrl}/time_entries/${entry.id}/delete`)
    const data = response.json()

    context.commit('deleteEntry', entry)

    return data
  },
  addEntry(context, entry) {
    context.commit('addEntry', entry)
  },
  replaceEntry(context, entry) {
    context.commit('replaceEntry', entry)
  },
  clearEntryForm(context) {
    context.commit('clearEntryForm')
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
  setSelectedMonth(context, month) {
    context.commit('setSelectedMonth', month)
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
