import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import FormField from '../FormField.vue'

describe('FormField', () => {
  it('renders the label, required marker, access key, and slot content', () => {
    const wrapper = mount(FormField, {
      props: {
        label: 'Project',
        accessKey: 'p',
        required: true,
        id: 'project',
      },
      slots: {
        default: '<input id="project" class="project-input">',
      },
    })

    expect(wrapper.find('label').attributes('for')).toBe('project')
    expect(wrapper.find('label').text()).toContain('Project')
    expect(wrapper.find('.tracker-entry-form-field-required').text()).toBe('*')
    expect(wrapper.find('.tracker-entry-form-field-accesskey').text()).toBe('alt-p')
    expect(wrapper.find('.project-input').exists()).toBe(true)
  })

  it('renders a field tag with the first label letter and configured CSS variable', () => {
    const wrapper = mount(FormField, {
      props: {
        label: 'Category',
        fieldTagColorVariable: '--category-color',
      },
    })

    const tag = wrapper.find('.tracker-entry-form-field-tag')

    expect(tag.text()).toBe('C')
  })
})
