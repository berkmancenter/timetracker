import { createStore } from 'vuex'
import tracker from './modules/tracker'

export default createStore({
  modules: {
    tracker: tracker
  }
})
