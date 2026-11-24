import fetchIt, { csrfToken } from '@/lib/fetch-it'
import { authType } from '@/lib/app-settings'
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
  },
  // What the last ping found out, see plugins/server-ping.js
  server: {
    reachable: true,
    newVersion: false,
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
  setServerReachable(state, reachable) {
    state.server.reachable = reachable
  },
  setNewVersion(state) {
    state.server.newVersion = true
  },
}

const actions = {
  async fetchUser(context) {
    const response = await fetchIt(`${apiUrl}/users/current_user_data`)
    const data = await response.json()

    return data
  },
  async logout(context) {
    switch (authType()) {
      case 'cas':
        submitLogoutForm(`${apiUrl}/users/cas_logout`)

        break
      case 'saml':
        submitLogoutForm()

        break
      default:
        await fetchIt(`${apiUrl}/users/sign_out`, {
          method: 'DELETE',
        })

        window.location.reload()
    }
  },
  setUser(context, user) {
    context.commit('setUser', user)
    context.commit('setSudoMode', user.sudo_users.length > 0)
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

  state.layout.sideMenuStatus = store2('timetracker.side_menu_status')
}

initLocalStorage()

function submitLogoutForm(action = `${apiUrl}/users/sign_out`) {
  const form = document.createElement('form')
  const methodInput = document.createElement('input')
  const tokenInput = document.createElement('input')

  form.method = 'POST'
  form.action = action

  methodInput.type = 'hidden'
  methodInput.name = '_method'
  methodInput.value = 'delete'

  tokenInput.type = 'hidden'
  tokenInput.name = 'authenticity_token'
  tokenInput.value = csrfToken() || ''

  form.appendChild(methodInput)
  form.appendChild(tokenInput)
  document.body.appendChild(form)
  form.submit()
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}
