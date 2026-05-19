import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import PopularItems from '../PopularItems.vue'

function mountPopularItems(items = ['Research', 'Writing']) {
  const dispatch = vi.fn()
  const emit = vi.fn()
  const wrapper = mount(PopularItems, {
    props: {
      title: 'Project',
      type: 'project',
      items,
    },
    global: {
      mocks: {
        $store: { dispatch },
        mitt: { emit },
      },
    },
  })

  return { wrapper, dispatch, emit }
}

describe('PopularItems', () => {
  it('renders popular items and selects one into the form', async () => {
    const { wrapper, dispatch, emit } = mountPopularItems()

    expect(wrapper.findAll('li').map((item) => item.text())).toEqual(['Research', 'Writing'])

    await wrapper.find('li').trigger('click')

    expect(dispatch).toHaveBeenCalledWith('tracker/clearEntryForm')
    expect(dispatch).toHaveBeenCalledWith('tracker/setFormField', { field: 'project', value: 'Research' })
    expect(emit).toHaveBeenCalledWith('popularSelected')
  })

  it('renders empty copy when there are no items', () => {
    const { wrapper } = mountPopularItems([])

    expect(wrapper.text()).toContain('Your most used project will show up here.')
  })
})
