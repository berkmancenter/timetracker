const formatIsoDateTimeToLocaleString = (isoString) => {
  const date = new Date(isoString)

  const formattedDate = date.toLocaleString([], {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
  })

  return formattedDate
}

const getTimestamp = (date) => {
  return new Date(date).getTime()
}

export {
  formatIsoDateTimeToLocaleString,
  getTimestamp,
}
