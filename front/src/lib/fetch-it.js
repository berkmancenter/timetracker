import { globals } from '@/main.js'

const fetchIt = async (url, options = {}) => {
  options.credentials = 'include'

  const response = await fetch(url, options)

  const responsePromise = new Promise((resolve, reject) => {
    if (response) {
      resolve(response)
    }
  })

  return responsePromise
}

export default fetchIt
