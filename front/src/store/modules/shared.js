import fetchIt from '@/lib/fetch-it'
import store2 from 'store2'

const apiUrl = import.meta.env.VITE_API_URL

const state = {
  user: {
    username: '',
    active_users: [],
    sudoMode: false,
    sideMenuStatus: false,
  },
}

const mutations = {
  setUser(state, user) {
    state.user = user
  },
  setSudoMode(state, isSudoMode) {
    state.user.sudoMode = isSudoMode
  },
  setSideMenuStatus(state, status) {
    state.sideMenuStatus = status
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
  setSideMenuStatus(context, status) {
    context.commit('setSideMenuStatus', status)
    store2('timetracker.side_menu_status', status)
  },
}

const getters = {}

function initLocalStorage() {
  if (store2('timetracker.side_menu_status') === null) {
    store2('timetracker.side_menu_status', false)
  }

  state.sideMenuStatus = store2('timetracker.side_menu_status')
}

initLocalStorage()

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}
