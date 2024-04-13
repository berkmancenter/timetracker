import { globals } from '@/main.js'

const environment = import.meta.env.VITE_ENVIRONMENT

const fetchIt = async (url, options = {}) => {
  if (environment === 'development') {
    options.credentials = 'include'
  }

  options.headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  }

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
