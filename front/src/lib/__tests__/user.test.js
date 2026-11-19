import { describe, expect, it } from 'vitest'

import { getUserIdentifier } from '../user'

describe('getUserIdentifier', () => {
  it('combines a complete name and email address', () => {
    expect(getUserIdentifier({
      first_name: 'Ada',
      last_name: 'Lovelace',
      email: 'ada@example.com',
    })).toBe('Ada Lovelace (ada@example.com)')
  })

  it('returns the complete name when email is absent', () => {
    expect(getUserIdentifier({ first_name: 'Ada', last_name: 'Lovelace' })).toBe('Ada Lovelace')
  })

  it('returns the email when the complete name is absent', () => {
    expect(getUserIdentifier({ first_name: 'Ada', email: 'ada@example.com' })).toBe('ada@example.com')
  })

  it('returns an empty string when no identifier is available', () => {
    expect(getUserIdentifier({})).toBe('')
  })
})
