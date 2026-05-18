import { describe, expect, it } from 'vitest'

import { getTimestamp } from '../date-time'

describe('date-time', () => {
  it('returns the timestamp for a date value', () => {
    expect(getTimestamp('2024-01-02T03:04:05.000Z')).toBe(1704164645000)
  })
})
