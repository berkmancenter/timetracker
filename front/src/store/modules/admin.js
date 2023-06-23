import fetchIt from '@/lib/fetch_it'

const apiUrl = import.meta.env.VITE_API_URL

const state = {
  users: [],
}

const mutations = {
  setUsers(state, users) {
    state.users = users
  },
}

const actions = {
  async fetchUsers(context) {
    const response = await fetchIt(`${apiUrl}/users`)
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
}

const getters = {}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}
