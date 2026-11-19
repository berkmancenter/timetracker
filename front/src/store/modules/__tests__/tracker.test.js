import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchIt: vi.fn(),
  router: { currentRoute: { _value: { params: {} } } },
  store2: vi.fn(),
}))

vi.mock('@/lib/fetch-it', () => ({ default: mocks.fetchIt }))
vi.mock('@/router/index', () => ({ router: mocks.router }))
vi.mock('store2', () => ({ default: mocks.store2 }))

import tracker from '../tracker'

function freshState(overrides = {}) {
  return {
    ...tracker.state,
    entries: [],
    months: [],
    timesheets: [],
    abortControllers: {},
    formEntry: { id: null, decimal_time: '', entry_date: '', fields: {} },
    ...overrides,
  }
}

describe('tracker store', () => {
  beforeEach(() => {
    mocks.fetchIt.mockReset()
    mocks.store2.mockReset()
    mocks.router.currentRoute._value.params = {}
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('marks entry list transitions and clears the marker asynchronously', () => {
    vi.useFakeTimers()
    const state = freshState()
    const entries = [{ id: 1 }]

    tracker.mutations.setEntries(state, entries)

    expect(state.entries).toBe(entries)
    expect(state.entriesBeforeChange).toBe(true)
    vi.runAllTimers()
    expect(state.entriesBeforeChange).toBe(false)
  })

  it('replaces and deletes entries by id without changing unrelated entries', () => {
    const state = freshState({ entries: [{ id: 1, hours: 1 }, { id: 2, hours: 2 }] })

    tracker.mutations.replaceEntry(state, { id: 1, hours: 3 })
    tracker.mutations.deleteEntry(state, { id: 2 })

    expect(state.entries).toEqual([{ id: 1, hours: 3 }])
  })

  it('aborts an earlier request and returns parsed response data', async () => {
    const abort = vi.fn()
    const state = freshState({ abortControllers: { fetchEntries: { abort } } })
    const data = [{ id: 4 }]
    mocks.fetchIt.mockResolvedValue({ json: vi.fn().mockResolvedValue(data) })

    await expect(tracker.actions.fetchGet(
      { state },
      { url: '/entries', methodName: 'fetchEntries' },
    )).resolves.toEqual(data)

    expect(abort).toHaveBeenCalledOnce()
    expect(mocks.fetchIt).toHaveBeenCalledWith('/entries', {
      method: 'GET',
      signal: expect.any(AbortSignal),
    })
  })

  it('returns an empty result and reports non-abort request failures', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    mocks.fetchIt.mockRejectedValue('network unavailable')

    await expect(tracker.actions.fetchGet(
      { state: freshState() },
      { url: '/entries', methodName: 'fetchEntries' },
    )).resolves.toEqual([])

    expect(error).toHaveBeenCalledWith('network unavailable /entries')
  })

  it('selects a valid route month and falls back to the newest available month', () => {
    const dispatch = vi.fn()
    const state = freshState({ months: ['2026-11', '2026-10'] })

    mocks.router.currentRoute._value.params = { month: '2026-10' }
    tracker.actions.setSelectedMonthFromRoute({ state, dispatch })
    expect(dispatch).toHaveBeenLastCalledWith('setSelectedMonth', '2026-10')

    mocks.router.currentRoute._value.params = { month: 'missing' }
    tracker.actions.setSelectedMonthFromRoute({ state, dispatch })
    expect(dispatch).toHaveBeenLastCalledWith('setSelectedMonth', '2026-11')
  })

  it('selects a route timesheet before local storage and list fallbacks', () => {
    const dispatch = vi.fn()
    const routeTimesheet = { id: 2, uuid: 'route-sheet' }
    const state = freshState({
      timesheets: [{ id: 1, uuid: 'first-sheet' }, routeTimesheet],
    })
    mocks.router.currentRoute._value.params = { timesheet: 'route-sheet' }

    tracker.actions.setSelectedTimesheetFromRoute({ state, dispatch })

    expect(dispatch).toHaveBeenCalledWith('setSelectedTimesheet', routeTimesheet)
  })

  it('adds entries only when they match the selected route month', () => {
    const commit = vi.fn()
    mocks.router.currentRoute._value.params = { month: '2026-11' }

    tracker.actions.addEntry({ commit }, { id: 1, entry_date: '2026-11-05' })
    tracker.actions.addEntry({ commit }, { id: 2, entry_date: '2026-10-05' })

    expect(commit).toHaveBeenCalledOnce()
    expect(commit).toHaveBeenCalledWith('addEntry', { id: 1, entry_date: '2026-11-05' })
  })
})
