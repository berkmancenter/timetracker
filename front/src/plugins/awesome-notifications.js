import AWN from 'awesome-notifications'
import 'awesome-notifications/dist/style.css'

const options = {
  position: 'top-right',
  durations: {
    global: 6000,
  },
  maxNotifications: 2,
}

export default new AWN(options)
