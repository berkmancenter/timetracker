import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Join from '../Join.vue'

function mountJoin(response = { ok: true }) {
  const dispatch = vi.fn(async (action) => {
    if (action === 'tracker/joinTimesheet') {
      if (response instanceof Error) throw response
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
  it('joins a timesheet and redirects without overwriting sidebar state', async () => {
    const { dispatch, push, emit, awn } = mountJoin()

    await new Promise((resolve) => setTimeout(resolve))

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(dispatch).toHaveBeenCalledWith('tracker/joinTimesheet', 'invite-code')
    expect(dispatch).not.toHaveBeenCalledWith('shared/setSideMenuStatus', expect.anything())
    expect(awn.success).toHaveBeenCalledWith('You have joined successfully.')
    expect(push).toHaveBeenCalledWith({ name: 'tracker.index' })
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('warns when joining fails', async () => {
    const { awn, emit } = mountJoin({ ok: false })

    await new Promise((resolve) => setTimeout(resolve))

    expect(awn.warning).toHaveBeenCalledWith('Something went wrong, try again.')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
  })

  it('stops the spinner and redirects when the request throws', async () => {
    const { awn, emit, push } = mountJoin(new Error('network error'))

    await new Promise((resolve) => setTimeout(resolve))

    expect(awn.warning).toHaveBeenCalledWith('Something went wrong, try again.')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(push).toHaveBeenCalledWith({ name: 'tracker.index' })
  })
})
