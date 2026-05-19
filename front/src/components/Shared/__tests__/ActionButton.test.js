import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import ActionButton from '../ActionButton.vue'

describe('ActionButton', () => {
  it('renders as a button when requested', () => {
    const wrapper = mount(ActionButton, {
      props: {
        button: true,
        buttonText: 'Save',
      },
    })

    expect(wrapper.element.tagName).toBe('BUTTON')
    expect(wrapper.text()).toContain('Save')
  })

  it('renders as a link by default', () => {
    const wrapper = mount(ActionButton, {
      props: {
        buttonText: 'Edit',
      },
    })

    expect(wrapper.element.tagName).toBe('A')
  })

  it('passes disabled state and active/icon classes to the root element', () => {
    const wrapper = mount(ActionButton, {
      props: {
        button: true,
        active: true,
        disabled: true,
        icon: '/icons/save.svg',
        iconPosition: 'right',
        buttonText: 'Save',
      },
    })

    expect(wrapper.attributes('disabled')).toBeDefined()
    expect(wrapper.classes()).toContain('tracker-action-button-active')
    expect(wrapper.classes()).toContain('tracker-action-button-icon-right')
    expect(wrapper.find('img').attributes('src')).toBe('/icons/save.svg')
  })

  it('calls the click handler when selected', async () => {
    const onClick = vi.fn()
    const wrapper = mount(ActionButton, {
      props: {
        buttonText: 'Save',
        onClick,
      },
    })

    await wrapper.trigger('click')

    expect(onClick).toHaveBeenCalledOnce()
  })
})
