// Additional libs
import './plugins/bulma'
import './plugins/autocomplete'
import './plugins/pace'
import './plugins/loading-css'
import mitt from './plugins/mitt'
import awn from './plugins/awesome-notifications'
import datepicker from './plugins/datepicker'

import { createApp } from 'vue'
import router from './router/index'
import store from './store/index'
import App from './App.vue'

const app = createApp(App)
app.config.globalProperties = {
  colors: {
    main: '#890309',
  },
  environment: import.meta.env.VITE_ENVIRONMENT || 'development',
  mitt: mitt,
  awn: awn,
}
app.use(router)
app.use(store)
app.use(datepicker)
app.mount('#app')

const globals = app.config.globalProperties
export { globals }
