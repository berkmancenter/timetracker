import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  autocomplete: vi.fn(),
}))

vi.mock('autocompleter', () => ({
  default: mocks.autocomplete,
}))

import EntryForm from '../EntryForm.vue'

function createStore(formMode = 'create') {
  const state = {
    tracker: {
      formMode,
      formEntry: {
        id: 2,
        decimal_time: '1.25',
        entry_date: 'May 19, 2026',
        fields: {
          project: '',
          description: '',
        },
      },
      selectedTimesheet: {
        uuid: 'alpha',
        custom_fields: [
          { id: 1, title: 'Project', machine_name: 'project', input_type: 'text', access_key: 'p' },
          { id: 2, title: 'Description', machine_name: 'description', input_type: 'long_text', access_key: 'd' },
        ],
      },
    },
  }

  const dispatch = vi.fn(async (action) => {
    if (action === 'tracker/submitEntryForm') return { id: 2, decimal_time: '1.25', fields: {} }
    if (action === 'tracker/fetchMonths') return ['May 2026']
    if (action === 'tracker/fetchAutoComplete') return ['Research']
    return undefined
  })
  const commit = vi.fn()

  return { state, dispatch, commit }
}

function mountEntryForm(store = createStore(), isTouchDevice = false) {
  const emit = vi.fn()
  const on = vi.fn()
  const wrapper = mount(EntryForm, {
    global: {
      mocks: {
        $store: store,
        mitt: { emit, on },
        isTouchDevice,
      },
      stubs: {
        Modal: {
          template: '<div class="modal-stub"><slot /></div>',
        },
        FormField: {
          props: ['label'],
          template: '<label class="form-field-stub">{{ label }}<slot /></label>',
        },
        DatePicker: {
          props: ['value'],
          template: '<input class="date-picker-stub">',
        },
        Icon: true,
        ActionButton: true,
      },
    },
  })

  return { wrapper, emit, on, store }
}

describe('EntryForm', () => {
  it('renders custom fields and submit button copy by mode', () => {
    const { wrapper } = mountEntryForm()

    expect(wrapper.text()).toContain('Project')
    expect(wrapper.text()).toContain('Description')
    expect(wrapper.text()).toContain('Time spent')
    expect(wrapper.vm.submitButtonName).toBe('Add entry')

    const editStore = createStore('edit')
    const { wrapper: editWrapper } = mountEntryForm(editStore)
    expect(editWrapper.vm.submitButtonName).toBe('Save changes')
  })

  it('commits changed autocomplete form values', () => {
    const { wrapper, store } = mountEntryForm()

    wrapper.vm.changeFormValue('project', 'Research')

    expect(store.commit).toHaveBeenCalledWith('tracker/setFormField', { field: 'project', value: 'Research' })
  })

  it('prevents invalid number key presses', () => {
    const { wrapper } = mountEntryForm()
    const preventDefault = vi.fn()

    wrapper.vm.isNumberKey({ which: 'x'.charCodeAt(0), target: { value: '' }, preventDefault })

    expect(preventDefault).toHaveBeenCalled()
  })

  it('opens the form, clears when requested, and initializes autocomplete', async () => {
    const { wrapper, store } = mountEntryForm()

    await wrapper.vm.openForm(true)

    expect(store.dispatch).toHaveBeenCalledWith('tracker/clearEntryForm')
    expect(wrapper.vm.visible).toBe(true)
    expect(mocks.autocomplete).toHaveBeenCalled()
  })

  it('submits create mode and refreshes dependent data', async () => {
    const { wrapper, store, emit } = mountEntryForm()
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)

    await wrapper.vm.submitForm()

    expect(emit).toHaveBeenCalledWith('modalIsWorking')
    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/submitEntryForm')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/addEntry', { id: 2, decimal_time: '1.25', fields: {} })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setMonths', ['May 2026'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['popular', 'periodTotals', 'totals'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/clearEntryForm')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(emit).toHaveBeenCalledWith('modalIsNotWorking')
    expect(wrapper.vm.visible).toBe(false)
  })

  it('submits edit mode by replacing the existing entry', async () => {
    const store = createStore('edit')
    const { wrapper } = mountEntryForm(store)
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)

    await wrapper.vm.submitForm()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/replaceEntry', { id: 2, decimal_time: '1.25', fields: {} })
  })

  it('does not submit when the form is invalid', async () => {
    const { wrapper, store } = mountEntryForm()
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => false)

    await wrapper.vm.submitForm()

    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/submitEntryForm')
  })
})
