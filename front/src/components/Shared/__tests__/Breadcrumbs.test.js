import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import Breadcrumbs from '../Breadcrumbs.vue'

describe('Breadcrumbs', () => {
  it('renders links and the current crumb', () => {
    const wrapper = mount(Breadcrumbs, {
      props: {
        crumbs: [
          { text: 'Timesheets', link: { name: 'timesheets.index' } },
          { text: 'Spring 2026' },
        ],
      },
      global: {
        stubs: {
          RouterLink: {
            props: ['to'],
            template: '<a class="router-link-stub" :data-to="JSON.stringify(to)"><slot /></a>',
          },
        },
      },
    })

    expect(wrapper.find('.router-link-stub').text()).toBe('Timesheets')
    expect(wrapper.find('.router-link-stub').attributes('data-to')).toBe('{"name":"timesheets.index"}')
    expect(wrapper.find('span').text()).toBe('Spring 2026')
  })

  it('marks only the last crumb as active', () => {
    const wrapper = mount(Breadcrumbs, {
      props: {
        crumbs: [
          { text: 'Home', link: '/' },
          { text: 'Tracker', link: '/tracker' },
          { text: 'Current' },
        ],
      },
      global: {
        stubs: ['RouterLink'],
      },
    })

    const items = wrapper.findAll('li')

    expect(items).toHaveLength(3)
    expect(items[0].classes()).not.toContain('is-active')
    expect(items[1].classes()).not.toContain('is-active')
    expect(items[2].classes()).toContain('is-active')
  })
})
