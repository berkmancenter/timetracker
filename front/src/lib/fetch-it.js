const fetchIt = async (url, options = {}) => {
  options.credentials = 'include'

  try {
    const response = await fetch(url, options)

    return response
  } catch (error) {
    return Promise.reject(error)
  }
}

export default fetchIt
