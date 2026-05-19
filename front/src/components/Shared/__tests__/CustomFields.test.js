import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import CustomFields from '../CustomFields.vue'

const iconStub = {
  props: ['src'],
  template: '<img class="tracker-icon" :src="src">',
}

function mountCustomFields(options = {}) {
  const dispatch = vi.fn()
  const wrapper = mount(CustomFields, {
    props: {
      fields: [],
      ...options.props,
    },
    global: {
      mocks: {
        $store: { dispatch },
      },
      stubs: {
        Icon: iconStub,
      },
    },
    slots: options.slots,
  })

  return { wrapper, dispatch }
}

describe('CustomFields', () => {
  it('renders visible fields sorted by order and ignores destroyed fields', () => {
    const { wrapper } = mountCustomFields({
      props: {
        fields: [
          { id: 1, title: 'Second', input_type: 'text', order: 2 },
          { id: 2, title: 'Removed', input_type: 'text', order: 1, _destroy: true },
          { id: 3, title: 'First', input_type: 'long_text', order: 1 },
        ],
      },
    })

    const titleInputs = wrapper.findAll('input[type="text"]')

    expect(titleInputs).toHaveLength(2)
    expect(titleInputs[0].element.value).toBe('First')
    expect(titleInputs[1].element.value).toBe('Second')
    expect(wrapper.text()).not.toContain('Removed')
  })

  it('shows the minimum field warning with pluralized copy', () => {
    const { wrapper } = mountCustomFields({
      props: {
        minRequiredFields: 2,
        fields: [{ id: 1, title: 'Only one', order: 1 }],
      },
    })

    expect(wrapper.find('.notification').text()).toContain('You need at least 2 fields')
  })

  it('defaults the input type when only one type is allowed', () => {
    const fields = [{ id: 1, title: 'Name', order: 1 }]

    mountCustomFields({
      props: {
        fields,
        types: [{ value: 'number', label: 'Number' }],
      },
    })

    expect(fields[0].input_type).toBe('number')
  })

  it('dispatches add and remove field actions', async () => {
    const field = { id: 1, title: 'Name', order: 1 }
    const { wrapper, dispatch } = mountCustomFields({
      props: {
        modelName: 'period',
        fields: [field],
      },
    })

    await wrapper.find('.custom-fields-add').trigger('click')
    await wrapper.find('[title="Remove field"]').trigger('click')

    expect(dispatch).toHaveBeenCalledWith('admin/addCustomField', 'period')
    expect(dispatch).toHaveBeenCalledWith('admin/removeCustomField', { field, modelName: 'period' })
  })

  it('reorders fields and emits the visible field list', async () => {
    const fields = [
      { id: 1, title: 'First', order: 1 },
      { id: 2, title: 'Second', order: 2 },
      { id: 3, title: 'Third', order: 3 },
    ]
    const { wrapper } = mountCustomFields({ props: { fields } })

    await wrapper.find('[title="Move down"]').trigger('click')

    expect(fields[0].order).toBe(2)
    expect(fields[1].order).toBe(1)
    expect(wrapper.emitted('fields-reordered')).toHaveLength(1)
    expect(wrapper.emitted('fields-reordered')[0][0].map((field) => field.id)).toEqual([2, 1, 3])
  })

  it('renders the additional fields slot for each visible field', () => {
    const { wrapper } = mountCustomFields({
      props: {
        fields: [{ id: 1, title: 'Name', order: 1 }],
      },
      slots: {
        'additional-fields': '<template #additional-fields="{ field, index }"><div class="extra">{{ index }}: {{ field.title }}</div></template>',
      },
    })

    expect(wrapper.find('.extra').text()).toBe('0: Name')
  })
})
