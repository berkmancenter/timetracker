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

  it('blocks clicks when disabled on link and button variants', async () => {
    const linkClick = vi.fn()
    const linkWrapper = mount(ActionButton, {
      props: {
        buttonText: 'Save',
        disabled: true,
        onClick: linkClick,
      },
    })

    expect(linkWrapper.element.tagName).toBe('A')
    expect(linkWrapper.attributes('aria-disabled')).toBe('true')
    expect(linkWrapper.attributes('tabindex')).toBe('-1')
    expect(linkWrapper.classes()).toContain('is-disabled')

    await linkWrapper.trigger('click')
    expect(linkClick).not.toHaveBeenCalled()

    const buttonClick = vi.fn()
    const buttonWrapper = mount(ActionButton, {
      props: {
        button: true,
        buttonText: 'Save',
        disabled: true,
        onClick: buttonClick,
      },
    })

    await buttonWrapper.trigger('click')
    expect(buttonClick).not.toHaveBeenCalled()
  })
})
