import { describe, expect, it } from 'vitest'

import { ariaSort, nextSortState, sortRows } from '../table-sort.js'

describe('table-sort', () => {
  it('computes next sort state and aria-sort attributes', () => {
    const initial = { key: null, direction: 'asc' }
    expect(ariaSort(initial, 'name')).toBe('none')

    const first = nextSortState(initial, 'name')
    expect(first).toEqual({ key: 'name', direction: 'asc' })
    expect(ariaSort(first, 'name')).toBe('ascending')
    expect(ariaSort(first, 'other')).toBe('none')

    const second = nextSortState(first, 'name')
    expect(second).toEqual({ key: 'name', direction: 'desc' })
    expect(ariaSort(second, 'name')).toBe('descending')

    const switched = nextSortState(second, 'created', 'desc')
    expect(switched).toEqual({ key: 'created', direction: 'desc' })
  })

  it('returns original order when key is missing', () => {
    const rows = [{ id: 2 }, { id: 1 }]
    expect(sortRows(rows, { key: null })).toEqual(rows)
  })

  it('sorts strings naturally and case-insensitively without mutating input', () => {
    const rows = [{ name: 'Item 10' }, { name: 'alpha' }, { name: 'Item 2' }]
    const asc = sortRows(rows, { key: 'name', direction: 'asc', type: 'string' })
    const desc = sortRows(rows, { key: 'name', direction: 'desc', type: 'string' })

    expect(asc.map((r) => r.name)).toEqual(['alpha', 'Item 2', 'Item 10'])
    expect(desc.map((r) => r.name)).toEqual(['Item 10', 'Item 2', 'alpha'])
    expect(rows.map((r) => r.name)).toEqual(['Item 10', 'alpha', 'Item 2'])
  })

  it('sorts numbers numerically and keeps empty values at the bottom', () => {
    const rows = [{ val: '10' }, { val: null }, { val: -2 }, { val: '2' }, { val: '' }]
    const asc = sortRows(rows, { key: 'val', direction: 'asc', type: 'number' })
    const desc = sortRows(rows, { key: 'val', direction: 'desc', type: 'number' })

    expect(asc.map((r) => r.val)).toEqual([-2, '2', '10', null, ''])
    expect(desc.map((r) => r.val)).toEqual(['10', '2', -2, null, ''])
  })

  it('sorts dates chronologically and keeps missing dates at the bottom', () => {
    const rows = [{ d: '2026-05-10' }, { d: null }, { d: '2026-04-01' }]
    const asc = sortRows(rows, { key: 'd', direction: 'asc', type: 'date' })
    const desc = sortRows(rows, { key: 'd', direction: 'desc', type: 'date' })

    expect(asc.map((r) => r.d)).toEqual(['2026-04-01', '2026-05-10', null])
    expect(desc.map((r) => r.d)).toEqual(['2026-05-10', '2026-04-01', null])
  })

  it('supports custom value getters', () => {
    const rows = [{ first: 'Grace' }, { first: 'Ada' }]
    const sorted = sortRows(rows, {
      key: 'identifier',
      direction: 'asc',
      getValue: (row) => row.first,
    })

    expect(sorted.map((r) => r.first)).toEqual(['Ada', 'Grace'])
  })
})
