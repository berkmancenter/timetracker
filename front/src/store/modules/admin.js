import fetchIt from '@/lib/fetch-it'

const apiUrl = import.meta.env.VITE_API_URL

const defaultPeriod = {
  name: '',
  from: '',
  to: '',
  custom_fields: [],
}

const defaultTimesheet = {
  name: '',
  custom_fields: [],
}

const defaultCustomField = {
  title: '',
  input_type: 'text',
  popular: false,
  list: false,
  order: 1,
  access_key: '',
}

const state = {
  users: [],
  periods: [],
  timesheets: [],
  period: JSON.parse(JSON.stringify(defaultPeriod)),
  timesheet: JSON.parse(JSON.stringify(defaultTimesheet)),
  timesheetInvitations: '',
  periodStats: {
    stats: [],
  },
  periodCredits: {
    credits: [],
  },
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
  setTimesheets(state, timesheets) {
    state.timesheets = timesheets
  },
  setTimesheet(state, timesheet) {
    state.timesheet = timesheet
  },
  setPeriodStats(state, periodStats) {
    state.periodStats = periodStats
  },
  setTimesheetInvitations(state, invitations) {
    state.timesheetInvitations = invitations
  },
  setPeriodCredits(state, periodCredits) {
    state.periodCredits = periodCredits
  },
  addCustomField(state, modelName) {
    let field = JSON.parse(JSON.stringify(defaultCustomField))

    if (typeof state[modelName].custom_fields === 'undefined') {
      state[modelName].custom_fields = []
    }

    field.order = state[modelName].custom_fields.length + 1
    state[modelName].custom_fields.push(field)
  },
  removeCustomField(state, field) {
    field._destroy = 1
  },
}

const actions = {
  async fetchTimesheetUsers(context, timesheetId) {
    const response = await fetchIt(`${apiUrl}/timesheets/${timesheetId}/users`)
    const data = await response.json()

    return data
  },
  async fetchPeriods(context, timesheetId) {
    const response = await fetchIt(`${apiUrl}/timesheets/${timesheetId}/periods`)
    const data = await response.json()

    return data
  },
  async fetchPeriod(context, periodData) {
    const response = await fetchIt(`${apiUrl}/timesheets/${periodData.timesheetId}/periods/${periodData.periodId}`)
    const data = await response.json()

    return data
  },
  async fetchTimesheets(context) {
    const response = await fetchIt(`${apiUrl}/timesheets`)
    const data = await response.json()

    return data
  },
  async fetchAdminTimesheets(context) {
    const response = await fetchIt(`${apiUrl}/timesheets/index_admin`)
    const data = await response.json()

    return data
  },
  async fetchTimesheet(context, id) {
    const response = await fetchIt(`${apiUrl}/timesheets/${id}`)
    const data = await response.json()

    return data
  },
  async fetchPeriodStats(context, periodData) {
    const response = await fetchIt(`${apiUrl}/timesheets/${periodData.timesheetId}/periods/${periodData.periodId}/stats`)
    const data = await response.json()

    return data
  },
  async fetchPeriodCredits(context, periodData) {
    const response = await fetchIt(`${apiUrl}/timesheets/${periodData.timesheetId}/periods/${periodData.periodId}/credits`)
    const data = await response.json()

    return data
  },
  async deleteUsersFromTimesheet(context, data) {
    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/delete_users`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: data.users,
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
  setTimesheet(context, timesheet) {
    context.commit('setTimesheet', timesheet)
  },
  setTimesheets(context, timesheets) {
    context.commit('setTimesheets', timesheets)
  },
  clearTimesheet(context) {
    context.commit('setTimesheet', JSON.parse(JSON.stringify(defaultTimesheet)))
  },
  setTimesheetInvitations(context, invitations) {
    context.commit('setTimesheetInvitations', invitations)
  },
  async savePeriod(context, data) {
    // To make Rails (API) happy we need to rename custom_fields to custom_fields_attributes
    data.period.custom_fields_attributes = data.period.custom_fields

    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/periods/upsert`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        period: data.period,
      }),
    })

    return response
  },
  async deleteTimesheets(context, timesheets) {
    const response = await fetchIt(`${apiUrl}/timesheets/delete`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        timesheets: timesheets,
      }),
    })

    return response
  },
  async saveTimesheet(context, timesheet) {
    // To make Rails (backend) happy we need to rename custom_fields to custom_fields_attributes
    timesheet.custom_fields_attributes = timesheet.custom_fields

    const response = await fetchIt(`${apiUrl}/timesheets/upsert`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        timesheet: timesheet,
      }),
    })

    return response
  },
  async deletePeriods(context, data) {
    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/periods/delete`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        periods: data.periods,
      }),
    })

    return response
  },
  async savePeriodCredits(context, data) {
    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/periods/${data.periodId}/set_credits`, {
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
  async clonePeriod(context, data) {
    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/periods/${data.periodId}/clone`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    })

    return response
  },
  async sendTimesheetInvitations(context, data) {
    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/send_invitations`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        emails: data.emails,
        role: data.role,
      }),
    })

    return response
  },
  async leaveTimesheet(context, timesheet) {
    const response = await fetchIt(`${apiUrl}/timesheets/${timesheet.id}/leave`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    })

    return response
  },
  async changeTimesheetUsersRole(context, data) {
    const response = await fetchIt(`${apiUrl}/timesheets/${data.timesheetId}/change_users_role`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: data.users,
        timesheet_id: data.timesheetId,
        role: data.role,
      }),
    })

    return response
  },
  addCustomField(context, modelName) {
    context.commit('addCustomField', modelName)
  },
  removeCustomField(context, field) {
    context.commit('removeCustomField', field)
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
