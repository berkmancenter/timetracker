// Additional libs
import './plugins/bulma'
import './plugins/autocomplete'
import './plugins/loading-css'
import mitt from './plugins/mitt'
import awn from './plugins/awesome-notifications'
import datepicker from './plugins/datepicker'
import floating from './plugins/floating-vue'
import './plugins/auth-ping'
import vfm from './plugins/vfm'
import { isTouchDevice } from '@/lib/mobile-helpers.js'

import { createApp } from 'vue'
import { router } from './router/index'
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
  isTouchDevice: isTouchDevice(),
}
app.use(router)
app.use(store)
app.use(datepicker)
app.use(floating)
app.use(vfm)
app.mount('#app')

const globals = app.config.globalProperties
export { globals }
