import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => {
  const values = new Map()
  const store2 = vi.fn((key, value) => {
    if (value !== undefined) {
      values.set(key, value)
    }
    return values.has(key) ? values.get(key) : null
  })

  return { fetchIt: vi.fn(), store2, values }
})

vi.mock('@/lib/fetch-it', () => ({ default: mocks.fetchIt }))
vi.mock('store2', () => ({ default: mocks.store2 }))

import shared from '../shared'

describe('shared store', () => {
  beforeEach(() => {
    mocks.fetchIt.mockReset()
    mocks.store2.mockClear()
    mocks.values.clear()
  })

  it('commits the current user and derives sudo mode', () => {
    const commit = vi.fn()
    const user = { username: 'admin', sudo_users: [2] }

    shared.actions.setUser({ commit }, user)

    expect(commit).toHaveBeenNthCalledWith(1, 'setUser', user)
    expect(commit).toHaveBeenNthCalledWith(2, 'setSudoMode', true)
  })

  it('persists side menu state after committing it', () => {
    const commit = vi.fn()

    shared.actions.setSideMenuStatus({ commit }, true)

    expect(commit).toHaveBeenCalledWith('setSideMenuStatus', true)
    expect(mocks.store2).toHaveBeenCalledWith('timetracker.side_menu_status', true)
  })

  it('returns parsed current user data from the API', async () => {
    const data = { username: 'person@example.com' }
    mocks.fetchIt.mockResolvedValue({ json: vi.fn().mockResolvedValue(data) })

    await expect(shared.actions.fetchUser({})).resolves.toEqual(data)
    expect(mocks.fetchIt).toHaveBeenCalledWith(expect.stringMatching(/\/users\/current_user_data$/))
  })
})
