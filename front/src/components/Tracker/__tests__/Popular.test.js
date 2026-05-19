import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import Popular from '../Popular.vue'

function mountPopular(customFields, popular) {
  return mount(Popular, {
    global: {
      mocks: {
        $store: {
          state: {
            tracker: {
              selectedTimesheet: { custom_fields: customFields },
              popular,
            },
          },
        },
      },
      stubs: {
        PopularItems: {
          props: ['title', 'type', 'items'],
          template: '<div class="popular-items-stub" :data-title="title" :data-type="type">{{ items.join(",") }}</div>',
        },
      },
    },
  })
}

describe('Popular', () => {
  it('renders popular fields that have matching popular items', () => {
    const wrapper = mountPopular(
      [
        { title: 'Project', machine_name: 'project', popular: true },
        { title: 'Private', machine_name: 'private', popular: false },
        { title: 'Category', machine_name: 'category', popular: true },
      ],
      {
        project: ['Research'],
      },
    )

    const items = wrapper.findAll('.popular-items-stub')

    expect(items).toHaveLength(1)
    expect(items[0].attributes('data-title')).toBe('Project')
    expect(items[0].attributes('data-type')).toBe('project')
    expect(items[0].text()).toBe('Research')
  })

  it('does not render a section without popular fields', () => {
    const wrapper = mountPopular([{ title: 'Project', machine_name: 'project', popular: false }], {})

    expect(wrapper.html()).toBe('<!--v-if-->')
  })
})
