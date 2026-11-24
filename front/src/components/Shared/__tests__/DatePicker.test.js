import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import DatePicker from '../DatePicker.vue'

describe('DatePicker', () => {
  it('formats modelValue, forwards input attributes, and applies accesskey', async () => {
    const wrapper = mount(DatePicker, {
      props: {
        modelValue: 'November 1, 2026',
        name: 'entry_date',
        id: 'time_entry_entry_date',
        required: true,
        accessKey: 'a',
      },
    })

    await wrapper.vm.$nextTick()
    const input = wrapper.find('input')

    expect(input.element.value).toBe('November 1, 2026')
    expect(input.attributes('name')).toBe('entry_date')
    expect(input.attributes('id')).toBe('time_entry_entry_date')
    expect(input.attributes('required')).toBeDefined()
    expect(input.attributes('accesskey')).toBe('a')
  })

  it('parses typed dates and emits formatted strings consistently west of UTC', async () => {
    const timeZone = process.env.TZ
    process.env.TZ = 'America/New_York'

    try {
      const wrapper = mount(DatePicker, {
        props: {
          modelValue: '',
          name: 'from',
        },
      })

      const input = wrapper.find('input')
      await input.setValue('November 30, 2026')

      expect(wrapper.emitted('update:modelValue')?.at(-1)).toEqual(['November 30, 2026'])
    } finally {
      process.env.TZ = timeZone
    }
  })
})
