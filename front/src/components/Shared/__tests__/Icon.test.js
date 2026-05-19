import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import Icon from '../Icon.vue'

describe('Icon', () => {
  it('renders the provided image source as interactive by default', () => {
    const wrapper = mount(Icon, {
      props: {
        src: '/icons/add.svg',
      },
    })

    expect(wrapper.attributes('src')).toBe('/icons/add.svg')
    expect(wrapper.classes()).toContain('tracker-icon-interactive')
  })

  it('can render as non-interactive', () => {
    const wrapper = mount(Icon, {
      props: {
        src: '/icons/add.svg',
        interactive: false,
      },
    })

    expect(wrapper.classes()).not.toContain('tracker-icon-interactive')
  })
})
