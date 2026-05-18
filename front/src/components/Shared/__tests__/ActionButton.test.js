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
