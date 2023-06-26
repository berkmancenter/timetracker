import fetchIt from '@/lib/fetch-it'

const apiUrl = import.meta.env.VITE_API_URL

const state = {
  user: {
    username: '',
    active_users: [],
    sudoMode: false,
  },
}

const mutations = {
  setUser(state, user) {
    state.user = user
  },
  setSudoMode(state, isSudoMode) {
    state.user.sudoMode = isSudoMode
  },
}

const actions = {
  async fetchUser(context) {
    const response = await fetchIt(`${apiUrl}/users/current_user`)
    const data = await response.json()

    return data
  },
  setUser(context, user) {
    context.commit('setUser', user)
    context.commit('setSudoMode', user.active_users.length > 1)
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
