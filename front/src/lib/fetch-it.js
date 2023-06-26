import { globals } from '@/main.js'

const environment = import.meta.env.VITE_ENVIRONMENT

const fetchIt = async (url, options = {}) => {
  if (environment === 'development') {
    options.credentials = 'include'
  }

  let response
  try {
    response = await fetch(url, options)
  } catch (error) {
    globals.awn.warning('Your Harvard Key session has expired.<br>Please refresh the page.')
  }

  const responsePromise = new Promise((resolve, reject) => {
    if (response) {
      resolve(response)
    }
  })

  return responsePromise
}

export default fetchIt;
