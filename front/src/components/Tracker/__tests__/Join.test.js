import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Join from '../Join.vue'

function mountJoin(response = { ok: true }) {
  const dispatch = vi.fn(async (action) => {
    if (action === 'tracker/joinTimesheet') {
      return response
    }

    return undefined
  })
  const push = vi.fn()
  const emit = vi.fn()
  const awn = {
    success: vi.fn(),
    warning: vi.fn(),
  }

  const wrapper = mount(Join, {
    global: {
      mocks: {
        $store: { dispatch },
        $route: { params: { code: 'invite-code' } },
        $router: { push },
        mitt: { emit },
        awn,
      },
    },
  })

  return { wrapper, dispatch, push, emit, awn }
}

describe('Join', () => {
  it('sets the join layout on creation', () => {
    const { dispatch } = mountJoin()

    expect(dispatch).toHaveBeenCalledWith('shared/setSideMenuEnabled', false)
    expect(dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', false)
  })

  it('joins a timesheet, restores tracker layout, and redirects', async () => {
    const { dispatch, push, emit, awn } = mountJoin()

    await new Promise((resolve) => setTimeout(resolve))

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(dispatch).toHaveBeenCalledWith('tracker/joinTimesheet', 'invite-code')
    expect(awn.success).toHaveBeenCalledWith('You have joined successfully.')
    expect(push).toHaveBeenCalledWith({ name: 'tracker.index' })
    expect(dispatch).toHaveBeenCalledWith('shared/setSideMenuEnabled', true)
    expect(dispatch).toHaveBeenCalledWith('shared/setSideMenuStatus', true)
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('warns when joining fails', async () => {
    const { awn } = mountJoin({ ok: false })

    await new Promise((resolve) => setTimeout(resolve))

    expect(awn.warning).toHaveBeenCalledWith('Something went wrong, try again.')
  })
})
