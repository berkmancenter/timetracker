import fetchIt from '@/lib/fetch-it'

const apiUrl = import.meta.env.VITE_API_URL

const defaultPeriod = {
  name: '',
  from: '',
  to: '',
}

const defaultTimesheet = {
  name: '',
  timesheet_fields: [],
}

const defaultTimesheetField = {
  title: '',
  input_type: 'text',
  popular: false,
  list: false,
  order: 1,
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
  addTimesheetField(state) {
    let field = JSON.parse(JSON.stringify(defaultTimesheetField))
    field.order = state.timesheet.timesheet_fields.length + 1
    state.timesheet.timesheet_fields.push(field)
  },
  removeTimesheetField(state, field) {
    field._destroy = 1
  },
}

const actions = {
  async fetchTimesheetUsers(context, timesheetId) {
    const response = await fetchIt(`${apiUrl}/timesheets/${timesheetId}/users`)
    const data = await response.json()

    return data
  },
  async fetchPeriods(context) {
    const response = await fetchIt(`${apiUrl}/periods`)
    const data = await response.json()

    return data
  },
  async fetchPeriod(context, id) {
    const response = await fetchIt(`${apiUrl}/periods/${id}`)
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
  async unsudoUsersTimesheet(context, users) {
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
    timesheet.timesheet_fields_attributes = timesheet.timesheet_fields
    delete timesheet.timesheet_fields

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
  async clonePeriod(context, periodId) {
    const response = await fetchIt(`${apiUrl}/periods/${periodId}/clone`, {
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
  addTimesheetField(context) {
    context.commit('addTimesheetField')
  },
  removeTimesheetField(context, field) {
    context.commit('removeTimesheetField', field)
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
