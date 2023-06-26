function cleanUsername(username) {
  return username.replace(/\.law\.harvard\.edu|\.harvard\.edu/g, '')
}

export default cleanUsername
