import { afterEach, describe, expect, it, vi } from 'vitest'

import { redirectToSelectedMonth, router } from '../index'

describe('router', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('registers tracker, administration, period, and invitation routes', () => {
    const routeNames = router.getRoutes().map(route => route.name)

    expect(routeNames).toEqual(expect.arrayContaining([
      'app.index',
      'tracker.index',
      'tracker.period.user',
      'timesheets.index',
      'timesheets.join',
      'periods.stats',
    ]))
  })

  it('redirects to the selected timesheet and month', () => {
    const replace = vi.spyOn(router, 'replace').mockResolvedValue()
    const store = {
      state: {
        tracker: {
          selectedTimesheet: { uuid: 'research-hours' },
          selectedMonth: '2026-11',
        },
      },
    }

    redirectToSelectedMonth(store)

    expect(replace).toHaveBeenCalledWith({
      name: 'tracker.index',
      params: {
        timesheet: 'research-hours',
        month: '2026-11',
      },
    })
  })
})
