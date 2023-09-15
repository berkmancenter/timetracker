import { globals } from '@/main.js'

const fetchIt = async (url, options = {}) => {
  options.credentials = 'include'

  let response
  try {
    response = await fetch(url, options)
  } catch (error) {
    globals.awn.warning('Something went wrong.<br>Please refresh the page or try again later.')
  }

  const responsePromise = new Promise((resolve, reject) => {
    if (response) {
      resolve(response)
    }
  })

  return responsePromise
}

export default fetchIt
