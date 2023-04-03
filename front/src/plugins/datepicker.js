import DatePicker from 'vue-datepicker-next'
import 'vue-datepicker-next/index.css'

export default {
  install: (app, options) => {
    app.component('date-picker', DatePicker)
  }
}
