

const getUserIdentifier = (data) => {
  const hasName = data.first_name && data.last_name
  const hasEmail = data.email

  if (hasName && hasEmail) {
    return `${data.first_name} ${data.last_name} (${data.email})`
  }

  if (hasName) {
    return `${data.first_name} ${data.last_name}`
  }

  if (hasEmail) {
    return data.email
  }

  return '';
};


export {
  getUserIdentifier,
}
