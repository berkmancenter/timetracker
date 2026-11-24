import '@vuepic/vue-datepicker/dist/main.css'
import DatePicker from '@/components/Shared/DatePicker.vue'

export default {
  install: (app) => {
    app.component('date-picker', DatePicker)
  },
}
