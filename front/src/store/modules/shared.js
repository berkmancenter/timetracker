import fetchIt from '@/lib/fetch-it'
import store2 from 'store2'

const apiUrl = import.meta.env.VITE_API_URL

const state = {
  user: {
    username: '',
    sudo_users: [],
    sudoMode: false,
  },
  layout: {
    sideMenuStatus: false,
    sideMenuEnabled: true,
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
    state.layout.sideMenuStatus = status
  },
  setSideMenuEnabled(state, enabled) {
    state.layout.sideMenuEnabled = enabled
  },
}

const actions = {
  async fetchUser(context) {
    const response = await fetchIt(`${apiUrl}/users/current_user_data`)
    const data = await response.json()

    return data
  },
  setUser(context, user) {
    context.commit('setUser', user)
    context.commit('setSudoMode', user.sudo_users.length > 0)
  },
  setSideMenuStatus(context, status) {
    context.commit('setSideMenuStatus', status)
    store2('timetracker.side_menu_status', status)
  },
  setSideMenuEnabled(context, enabled) {
    context.commit('setSideMenuEnabled', enabled)
  },
}

const getters = {}

function initLocalStorage() {
  if (store2('timetracker.side_menu_status') === null) {
    store2('timetracker.side_menu_status', false)
  }

  state.layout.sideMenuStatus = store2('timetracker.side_menu_status')
}

initLocalStorage()

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}
