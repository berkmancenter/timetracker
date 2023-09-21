const fetchIt = async (url, options = {}) => {
  options.credentials = 'include'

  try {
    const response = await fetch(url, options)

    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`)
    }

    return response
  } catch (error) {
    return Promise.reject(error)
  }
}

export default fetchIt
