const interval = 5000
const apiUrl = import.meta.env.VITE_API_URL
const environment = import.meta.env.VITE_ENVIRONMENT

const ping = () => {
  const xhr = new XMLHttpRequest()

  xhr.open('GET', `${apiUrl}/ping`, true)

  xhr.onreadystatechange = function() {
    if (xhr.status === 0 && window.navigator.onLine) {
      window.location.reload()
    }
  }

  xhr.send()
}

setInterval(ping, interval)
