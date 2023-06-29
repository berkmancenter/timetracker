import fetchIt from '@/lib/fetch-it'

const apiUrl = import.meta.env.VITE_API_URL

const defaultPeriod = {
  name: '',
  from: '',
  to: '',
}

const state = {
  users: [],
  periods: [],
  period: JSON.parse(JSON.stringify(defaultPeriod)),
  periodStats: {},
  periodCredits: {},
}

const mutations = {
  setUsers(state, users) {
    state.users = users
  },
  setPeriods(state, periods) {
    state.periods = periods
  },
  setPeriod(state, period) {
    state.period = period
  },
  setPeriodStats(state, periodStats) {
    state.periodStats = periodStats
  },
  setPeriodCredits(state, periodCredits) {
    state.periodCredits = periodCredits
  },
}

const actions = {
  async fetchUsers(context) {
    const response = await fetchIt(`${apiUrl}/users`)
    const data = await response.json()

    return data
  },
  async fetchPeriods(context) {
    const response = await fetchIt(`${apiUrl}/periods`)
    const data = await response.json()

    return data
  },
  async fetchPeriodStats(context, id) {
    const response = await fetchIt(`${apiUrl}/periods/${id}/stats`)
    const data = await response.json()

    return data
  },
  async fetchPeriodCredits(context, id) {
    const response = await fetchIt(`${apiUrl}/periods/${id}/credits`)
    const data = await response.json()

    return data
  },
  async fetchPeriod(context, id) {
    const response = await fetchIt(`${apiUrl}/periods/${id}`)
    const data = await response.json()

    return data
  },
  async deleteUsers(context, users) {
    const response = await fetchIt(`${apiUrl}/users/delete`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: users,
      }),
    })

    return response
  },
  async toggleAdminUsers(context, users) {
    const response = await fetchIt(`${apiUrl}/users/toggle_admin`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: users,
      }),
    })

    return response
  },
  setUsers(context, users) {
    context.commit('setUsers', users)
  },
  setPeriods(context, periods) {
    context.commit('setPeriods', periods)
  },
  setPeriodStats(context, periodStats) {
    context.commit('setPeriodStats', periodStats)
  },
  setPeriodCredits(context, periodCredits) {
    context.commit('setPeriodCredits', periodCredits)
  },
  clearPeriod(context) {
    context.commit('setPeriod', JSON.parse(JSON.stringify(defaultPeriod)))
  },
  setPeriod(context, period) {
    context.commit('setPeriod', period)
  },
  async sudo(context, users) {
    const response = await fetchIt(`${apiUrl}/users/sudo`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: users,
      }),
    })

    return response
  },
  async unSudo(context, users) {
    const response = await fetchIt(`${apiUrl}/users/sudo`, {
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
  async savePeriod(context, period) {
    const response = await fetchIt(`${apiUrl}/periods/upsert`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        period: period,
      }),
    })

    return response
  },
  async deletePeriods(context, periods) {
    const response = await fetchIt(`${apiUrl}/periods/delete`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        periods: periods,
      }),
    })

    return response
  },
  async savePeriodCredits(context, data) {
    const response = await fetchIt(`${apiUrl}/periods/${data.id}/set_credits`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        credits: data.credits,
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
