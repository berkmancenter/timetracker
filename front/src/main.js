// Additional libs
import 'bulma'
import DatePicker from 'vue-datepicker-next'
import 'vue-datepicker-next/index.css'
import 'autocompleter/autocomplete.css'

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
  }
  app.use(router)
  app.use(store)
  app.component('date-picker', DatePicker)
  app.mount('#app')
});
