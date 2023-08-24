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
  workspaces: [],
  months: [],
  entries: [],
  selectedMonth: 'all',
  selectedWorkspace: {},
  formEntry: JSON.parse(JSON.stringify(defaultEntry)),
  formMode: 'create',
  popular: {
    categories: [],
    projects: [],
  },
  dailyTotals: [],
}

const mutations = {
  setWorkspaces(state, workspaces) {
    state.workspaces = workspaces
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
  setSelectedWorkspace(state, workspace) {
    state.selectedWorkspace = workspace
  },
}

const actions = {
  async fetchMonths(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/months?workspace_uuid=${context.state.selectedWorkspace.uuid}`)
    const data = await response.json()

    return data
  },
  async fetchWorkspaces(context) {
    const response = await fetchIt(`${apiUrl}/workspaces`)
    const data = await response.json()

    return data
  },
  async fetchEntries(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/entries?month=${context.state.selectedMonth}&workspace_uuid=${context.state.selectedWorkspace.uuid}`)
    const data = await response.json()

    return data
  },
  async fetchPopular(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/popular`)
    const data = await response.json()

    return data
  },
  async fetchDailyTotals(context) {
    const response = await fetchIt(`${apiUrl}/time_entries/days?month=${context.state.selectedMonth}&workspace_uuid=${context.state.selectedWorkspace.uuid}`)
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
        workspace_uuid: context.state.selectedWorkspace.uuid,
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
  setWorkspaces(context, workspaces) {
    context.commit('setWorkspaces', workspaces)

    const currentWorkspaceParam = router.currentRoute._value.params?.workspace
    const workspaceFromRoute = workspaces.find(workspace => workspace.uuid === currentWorkspaceParam)
    if (workspaceFromRoute) {
      context.dispatch('setSelectedWorkspace', workspaceFromRoute)
    } else {
      if (workspaces.length > 0) {
        context.dispatch('setSelectedWorkspace', workspaces[0])
      }
    }
  },
  setSelectedMonth(context, month) {
    context.commit('setSelectedMonth', month)
  },
  setSelectedWorkspace(context, workspace) {
    context.commit('setSelectedWorkspace', workspace)
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
