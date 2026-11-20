import { beforeEach, describe, expect, it, vi } from 'vitest'

const { fetchIt } = vi.hoisted(() => ({ fetchIt: vi.fn() }))

vi.mock('@/lib/fetch-it', () => ({ default: fetchIt }))

import admin from '../admin'

function freshState() {
  return {
    ...admin.state,
    period: { name: '', custom_fields: [] },
    timesheet: { name: '', custom_fields: [] },
  }
}

describe('admin store', () => {
  beforeEach(() => {
    fetchIt.mockReset()
  })

  it('adds independent custom fields with sequential order values', () => {
    const state = freshState()

    admin.mutations.addCustomField(state, 'timesheet')
    admin.mutations.addCustomField(state, 'timesheet')

    expect(state.timesheet.custom_fields).toHaveLength(2)
    expect(state.timesheet.custom_fields.map(field => field.order)).toEqual([1, 2])
    state.timesheet.custom_fields[0].title = 'Changed'
    expect(state.timesheet.custom_fields[1].title).toBe('')
  })

  it('initializes a missing custom field collection', () => {
    const state = freshState()
    state.period = {}

    admin.mutations.addCustomField(state, 'period')

    expect(state.period.custom_fields).toHaveLength(1)
    expect(state.period.custom_fields[0].input_type).toBe('text')
  })

  it('marks removed custom fields for Rails nested attributes', () => {
    const field = { id: 5 }

    admin.mutations.removeCustomField(freshState(), field)

    expect(field._destroy).toBe(1)
  })

  it('serializes custom fields when saving a timesheet', async () => {
    const response = { ok: true }
    const timesheet = { name: 'Research', custom_fields: [{ title: 'Project' }] }
    fetchIt.mockResolvedValue(response)

    await expect(admin.actions.saveTimesheet({}, timesheet)).resolves.toBe(response)

    expect(timesheet.custom_fields_attributes).toBe(timesheet.custom_fields)
    expect(fetchIt).toHaveBeenCalledWith(
      expect.stringMatching(/\/timesheets\/upsert$/),
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ timesheet }),
      }),
    )
  })

  it('returns parsed timesheet data from the API', async () => {
    const data = { id: 8, name: 'Research' }
    fetchIt.mockResolvedValue({ json: vi.fn().mockResolvedValue(data) })

    await expect(admin.actions.fetchTimesheet({}, 8)).resolves.toEqual(data)
    expect(fetchIt).toHaveBeenCalledWith(expect.stringMatching(/\/timesheets\/8$/))
  })

  it('uses DELETE when leaving a timesheet', async () => {
    const response = { ok: true }
    fetchIt.mockResolvedValue(response)

    await expect(admin.actions.leaveTimesheet({}, { id: 8 })).resolves.toBe(response)

    expect(fetchIt).toHaveBeenCalledWith(
      expect.stringMatching(/\/timesheets\/8\/leave$/),
      expect.objectContaining({ method: 'DELETE' }),
    )
  })
})
