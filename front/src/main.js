// Additional libs
import './plugins/bulma'
import datepicker from './plugins/datepicker'
import './plugins/autocomplete'
import './plugins/pace'

import { createApp } from 'vue'
import router from './router/index'
import store from './store/index'
import App from './App.vue'

document.addEventListener('DOMContentLoaded', function() {
  const app = createApp(App)
  app.config.globalProperties = {
    colors: {
      main: '#890309',
    },
    environment: import.meta.env.VITE_ENVIRONMENT || 'development',
  }
  app.use(router)
  app.use(store)
  app.use(datepicker)
  app.mount('#app')
});
