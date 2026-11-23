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

  it('returns parsed response data', async () => {
    const data = [{ id: 4 }]
    mocks.fetchIt.mockResolvedValue({ ok: true, json: vi.fn().mockResolvedValue(data) })

    await expect(tracker.actions.fetchGet(
      { state: freshState() },
      { url: '/entries', methodName: 'fetchEntries' },
    )).resolves.toEqual(data)

    expect(mocks.fetchIt).toHaveBeenCalledWith('/entries', {
      method: 'GET',
      signal: expect.any(AbortSignal),
    })
  })

  it('aborts an older request without giving it the result of the newer one', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const signals = {}
    mocks.fetchIt.mockImplementation((url, { signal }) => new Promise((resolve, reject) => {
      signals[url] = signal

      if (url === '/entries?month=old') {
        signal.addEventListener('abort', () => reject('The user aborted a request.'))
      } else {
        resolve({ ok: true, json: async () => [{ id: 2 }] })
      }
    }))

    const older = tracker.actions.fetchGet({ state: freshState() }, { url: '/entries?month=old', methodName: 'fetchEntries' })
    const newer = tracker.actions.fetchGet({ state: freshState() }, { url: '/entries?month=new', methodName: 'fetchEntries' })

    await expect(older).rejects.toMatchObject({ name: 'AbortError' })
    await expect(newer).resolves.toEqual([{ id: 2 }])
    expect(signals['/entries?month=old'].aborted).toBe(true)
    expect(error).not.toHaveBeenCalled()
  })

  it('throws and reports network and HTTP failures', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})

    mocks.fetchIt.mockRejectedValueOnce('network unavailable')
    await expect(tracker.actions.fetchGet(
      { state: freshState() },
      { url: '/entries', methodName: 'fetchEntries' },
    )).rejects.toBe('network unavailable')
    expect(error).toHaveBeenCalledWith('network unavailable /entries')

    mocks.fetchIt.mockResolvedValueOnce({ ok: false, status: 500, json: vi.fn() })
    await expect(tracker.actions.fetchGet(
      { state: freshState() },
      { url: '/totals', methodName: 'fetchTotals' },
    )).rejects.toThrow('HTTP 500')
  })

  it('keeps the shown data of items which failed to reload', async () => {
    const commit = vi.fn()
    const totals = { total_hours_current_month: 1, total_hours_current_timesheet: 2 }
    const dispatch = vi.fn(async (action) => {
      if (action === 'fetchEntries') throw new Error('HTTP 500')
      return totals
    })

    await tracker.actions.reloadViewData({ dispatch, commit }, ['entries', 'totals'])

    expect(commit).toHaveBeenCalledOnce()
    expect(commit).toHaveBeenCalledWith('setTotals', totals)
  })

  it('encodes autocomplete parameters and keeps separate request slots for every field', async () => {
    const dispatch = vi.fn()
    const state = freshState({ selectedTimesheet: { uuid: 'alpha' } })

    await tracker.actions.fetchAutoComplete({ state, dispatch }, { field: 'project', term: 'r&d #1 + 50%' })
    await tracker.actions.fetchAutoComplete({ state, dispatch }, { field: 'description', term: 'notes' })

    expect(dispatch).toHaveBeenNthCalledWith(1, 'fetchGet', {
      url: expect.stringMatching(/\/time_entries\/auto_complete\?field=project&term=r%26d\+%231\+%2B\+50%25&timesheet_uuid=alpha$/),
      methodName: 'fetchAutoComplete:project',
    })
    expect(dispatch).toHaveBeenNthCalledWith(2, 'fetchGet', {
      url: expect.stringMatching(/\/time_entries\/auto_complete\?field=description&term=notes&timesheet_uuid=alpha$/),
      methodName: 'fetchAutoComplete:description',
    })
  })

  it('does not share the request slot of users and timesheets', async () => {
    const dispatch = vi.fn()
    const state = freshState({ selectedTimesheet: { id: 3 } })

    await tracker.actions.fetchUser({ state, dispatch }, 7)
    await tracker.actions.fetchTimesheets({ state, dispatch })

    expect(dispatch.mock.calls.map(([, options]) => options.methodName)).toEqual(['fetchUser', 'fetchTimesheets'])
  })

  it('throws when the time entry could not be saved', async () => {
    const state = freshState({ selectedTimesheet: { uuid: 'alpha' } })

    mocks.fetchIt.mockResolvedValueOnce({ ok: false, status: 400, json: vi.fn() })
    await expect(tracker.actions.submitEntryForm({ state })).rejects.toThrow('HTTP 400')

    mocks.fetchIt.mockResolvedValueOnce({ ok: true, json: async () => ({ id: 5 }) })
    await expect(tracker.actions.submitEntryForm({ state })).resolves.toEqual({ id: 5 })
  })

  it('uses the current day as the date of a cleared entry form', () => {
    vi.useFakeTimers()
    const state = freshState()

    vi.setSystemTime(new Date(2026, 10, 23, 23, 59))
    tracker.mutations.clearEntryForm(state)
    expect(state.formEntry.entry_date).toBe('November 23, 2026')

    vi.setSystemTime(new Date(2026, 10, 24, 0, 1))
    tracker.mutations.clearEntryForm(state)
    expect(state.formEntry.entry_date).toBe('November 24, 2026')
  })

  it('uses non-GET methods for deletion and invitation redemption', async () => {
    const response = { ok: true }
    const commit = vi.fn()
    mocks.fetchIt.mockResolvedValue(response)

    await tracker.actions.deleteEntry({ commit }, { id: 12 })
    await tracker.actions.joinTimesheet({}, 'invite-code')

    expect(mocks.fetchIt).toHaveBeenNthCalledWith(
      1,
      expect.stringMatching(/\/time_entries\/12\/delete$/),
      { method: 'DELETE' },
    )
    expect(mocks.fetchIt).toHaveBeenNthCalledWith(
      2,
      expect.stringMatching(/\/timesheets\/join\/invite-code$/),
      { method: 'POST' },
    )
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
