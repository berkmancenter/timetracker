import { globals } from '@/main.js'

const environment = import.meta.env.VITE_ENVIRONMENT

const fetchIt = async (url, options = {}) => {
  if (environment === 'development') {
    options.credentials = 'include'
  }

  options.headers = {
    'Accept': 'application/json',
  }

  let response
  try {
    response = await fetch(url, options)
  } catch (error) {
    // Aborted requests are ok, we don't need to notify the client
    if (error.message.includes('aborted') === false) {
      globals.awn.warning('Something went wrong, try again.')
    }
  }

  const responsePromise = new Promise((resolve, reject) => {
    if (response) {
      resolve(response)
    } else {
      reject()
    }
  })

  return responsePromise
}

export default fetchIt
