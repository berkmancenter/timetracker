import { globals } from '@/main.js'

const environment = import.meta.env.VITE_ENVIRONMENT
const SAFE_METHODS = ['GET', 'HEAD', 'OPTIONS']

const csrfToken = () => {
  const cookie = document.cookie
    .split('; ')
    .find(row => row.startsWith('CSRF-TOKEN='))

  return cookie ? decodeURIComponent(cookie.split('=').slice(1).join('=')) : null
}

const fetchIt = async (url, options = {}) => {
  options = { ...options }

  if (environment === 'development') {
    options.credentials = 'include'
  }

  options.headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...options.headers,
  }

  const method = (options.method || 'GET').toUpperCase()
  const token = csrfToken()
  if (!SAFE_METHODS.includes(method) && token) options.headers['X-CSRF-Token'] = token

  let response
  let errorMessage
  try {
    response = await fetch(url, options)
  } catch (error) {
    errorMessage = errorMessage = error.message
  }

  const responsePromise = new Promise((resolve, reject) => {
    if (response) {
      resolve(response)
    } else {
      reject(errorMessage)
    }
  })

  return responsePromise
}

export default fetchIt
export { csrfToken }
