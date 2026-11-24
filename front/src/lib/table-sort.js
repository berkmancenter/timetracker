export function nextSortState(current, key, defaultDirection = 'asc') {
  if (current.key === key) {
    return {
      key,
      direction: current.direction === 'asc' ? 'desc' : 'asc',
    }
  }

  return {
    key,
    direction: defaultDirection,
  }
}

export function ariaSort(current, key) {
  if (current.key !== key) return 'none'
  return current.direction === 'asc' ? 'ascending' : 'descending'
}

function toComparableNumber(value) {
  if (value === null || value === undefined || value === '') return null
  const parsed = Number(value)
  return Number.isNaN(parsed) ? null : parsed
}

function toComparableDate(value) {
  if (!value) return null
  const timestamp = Date.parse(value)
  return Number.isNaN(timestamp) ? null : timestamp
}

export function sortRows(rows, { key, direction = 'asc', type = 'string', getValue } = {}) {
  if (!Array.isArray(rows) || !key) return rows || []

  const factor = direction === 'desc' ? -1 : 1
  const read = getValue || ((row) => row?.[key])

  return [...rows].sort((a, b) => {
    const rawA = read(a)
    const rawB = read(b)

    if (type === 'number') {
      const numA = toComparableNumber(rawA)
      const numB = toComparableNumber(rawB)
      if (numA === null && numB === null) return 0
      if (numA === null) return 1
      if (numB === null) return -1
      return (numA - numB) * factor
    }

    if (type === 'date') {
      const dateA = toComparableDate(rawA)
      const dateB = toComparableDate(rawB)
      if (dateA === null && dateB === null) return 0
      if (dateA === null) return 1
      if (dateB === null) return -1
      return (dateA - dateB) * factor
    }

    const strA = String(rawA ?? '')
    const strB = String(rawB ?? '')
    return strA.localeCompare(strB, undefined, { sensitivity: 'base', numeric: true }) * factor
  })
}
