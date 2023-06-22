import { createStore } from 'vuex'
import tracker from './modules/tracker'
import admin from './modules/admin'
import shared from './modules/shared'

export default createStore({
  modules: {
    tracker: tracker,
    admin: admin,
    shared: shared,
  }
})
