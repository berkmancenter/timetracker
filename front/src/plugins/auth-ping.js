const interval = 60000
const apiUrl = import.meta.env.VITE_API_URL

const ping = () => {
  const xhr = new XMLHttpRequest()

  xhr.open('GET', `${apiUrl}/ping`, true)
  xhr.withCredentials = true

  xhr.onreadystatechange = function() {
    if (xhr.responseURL.includes('users/sign_in')) {
      window.location.reload()
    }

    if (xhr.status === 0 && window.navigator.onLine) {
      window.location.reload()
    }
  }

  xhr.send()
}

setInterval(ping, interval)
