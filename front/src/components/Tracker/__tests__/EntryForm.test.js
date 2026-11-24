import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  autocomplete: vi.fn(() => ({ destroy: vi.fn() })),
}))

vi.mock('autocompleter', () => ({
  default: mocks.autocomplete,
}))

import EntryForm from '../EntryForm.vue'

function createStore(formMode = 'create', submit = async () => ({ id: 2, decimal_time: '1.25', fields: {} })) {
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
    if (action === 'tracker/submitEntryForm') return submit()
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
  const off = vi.fn()
  const awn = { warning: vi.fn() }
  const wrapper = mount(EntryForm, {
    global: {
      mocks: {
        $store: store,
        mitt: { emit, on, off },
        awn,
        isTouchDevice,
      },
      stubs: {
        Modal: {
          props: ['working'],
          template: '<div class="modal-stub" :data-working="working"><slot /></div>',
        },
        FormField: {
          props: ['label'],
          template: '<label class="form-field-stub">{{ label }}<slot /></label>',
        },
        DatePicker: {
          props: ['modelValue'],
          template: '<input class="date-picker-stub">',
        },
        Icon: true,
        ActionButton: true,
      },
    },
  })

  return { wrapper, emit, on, off, awn, store }
}

function deferred() {
  let resolve
  const promise = new Promise((done) => { resolve = done })

  return { promise, resolve }
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

  it('blocks keys which are not digits or a dot', () => {
    const { wrapper } = mountEntryForm()
    const preventDefault = vi.fn()

    wrapper.vm.isNumberKey({ key: 'x', preventDefault })
    wrapper.vm.isNumberKey({ key: '-', preventDefault })

    expect(preventDefault).toHaveBeenCalledTimes(2)
  })

  it('lets digits through also when the value already has two decimals', () => {
    const { wrapper } = mountEntryForm()
    const preventDefault = vi.fn()

    // "1.25" is selected and replaced, or a digit is typed before the dot
    wrapper.vm.isNumberKey({ key: '3', target: { value: '1.25' }, preventDefault })
    wrapper.vm.isNumberKey({ key: '.', target: { value: '' }, preventDefault })
    wrapper.vm.isNumberKey({ key: 'Enter', preventDefault })
    wrapper.vm.isNumberKey({ key: 'v', ctrlKey: true, preventDefault })

    expect(preventDefault).not.toHaveBeenCalled()
  })

  it('opens the form, clears when requested, and initializes autocomplete', async () => {
    const { wrapper, store } = mountEntryForm()

    await wrapper.vm.openForm(true)

    expect(store.dispatch).toHaveBeenCalledWith('tracker/clearEntryForm')
    expect(wrapper.vm.visible).toBe(true)
    expect(mocks.autocomplete).toHaveBeenCalled()
  })

  it('destroys the old autocomplete when the form opens again or closes', async () => {
    mocks.autocomplete.mockClear()
    const { wrapper } = mountEntryForm()

    await wrapper.vm.openForm()
    const first = mocks.autocomplete.mock.results[0].value

    await wrapper.vm.openForm()
    expect(first.destroy).toHaveBeenCalledOnce()

    const second = mocks.autocomplete.mock.results[1].value
    wrapper.vm.visible = false
    await wrapper.vm.$nextTick()
    expect(second.destroy).toHaveBeenCalledOnce()
  })

  it('renders autocomplete items as text, not as HTML', async () => {
    mocks.autocomplete.mockClear()
    const { wrapper } = mountEntryForm()

    await wrapper.vm.openForm()
    const options = mocks.autocomplete.mock.calls[0][0]
    const item = options.render({ label: 'R&D <img src=x onerror=alert(1)>' })

    expect(item.textContent).toBe('R&D <img src=x onerror=alert(1)>')
    expect(item.querySelector('img')).toBeNull()
  })

  it('shows no suggestions when the autocomplete request fails', async () => {
    mocks.autocomplete.mockClear()
    const store = createStore()
    const { wrapper } = mountEntryForm(store)
    store.dispatch.mockImplementation(async (action) => {
      if (action === 'tracker/fetchAutoComplete') throw new Error('HTTP 500')
    })

    await wrapper.vm.openForm()
    const update = vi.fn()
    await mocks.autocomplete.mock.calls[0][0].fetch('res', update)

    expect(update).toHaveBeenCalledWith([])
  })

  it('removes its event listeners when unmounted', () => {
    const { wrapper, on, off } = mountEntryForm()

    expect(on).toHaveBeenCalledTimes(4)

    wrapper.unmount()

    expect(off).toHaveBeenCalledTimes(4)
    on.mock.calls.forEach(([event, handler]) => {
      expect(off).toHaveBeenCalledWith(event, handler)
    })
  })

  it('submits create mode and refreshes dependent data', async () => {
    const { wrapper, store, emit } = mountEntryForm()
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)

    await wrapper.vm.submitForm()

    expect(emit).toHaveBeenCalledWith('spinnerStart')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/submitEntryForm')
    expect(store.dispatch).toHaveBeenCalledWith('tracker/addEntry', { id: 2, decimal_time: '1.25', fields: {} })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/setMonths', ['May 2026'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['popular', 'periodTotals', 'totals'])
    expect(store.dispatch).toHaveBeenCalledWith('tracker/clearEntryForm')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.working).toBe(false)
    expect(wrapper.vm.visible).toBe(false)
  })

  it('submits only once while a save is in progress', async () => {
    const save = deferred()
    const store = createStore('create', () => save.promise)
    const { wrapper } = mountEntryForm(store)
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)

    const firstSubmit = wrapper.vm.submitForm()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.modal-stub').attributes('data-working')).toBe('true')

    await wrapper.vm.submitForm()
    save.resolve({ id: 3, decimal_time: '1', fields: {} })
    await firstSubmit

    const submits = store.dispatch.mock.calls.filter(([action]) => action === 'tracker/submitEntryForm')
    expect(submits).toHaveLength(1)
  })

  it('keeps the form open and warns when saving fails', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    const store = createStore('create', async () => { throw new Error('HTTP 400') })
    const { wrapper, emit, awn } = mountEntryForm(store)
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)
    wrapper.vm.visible = true

    await wrapper.vm.submitForm()

    expect(awn.warning).toHaveBeenCalledWith('The time entry could not be saved, try again.')
    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/addEntry', expect.anything())
    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/clearEntryForm')
    expect(emit).toHaveBeenCalledWith('spinnerStop')
    expect(wrapper.vm.working).toBe(false)
    expect(wrapper.vm.visible).toBe(true)

    error.mockRestore()
  })

  it('submits edit mode by replacing the existing entry', async () => {
    const store = createStore('edit')
    const { wrapper } = mountEntryForm(store)
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)

    await wrapper.vm.submitForm()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/replaceEntry', { id: 2, decimal_time: '1.25', fields: {} })
  })

  it('reloads period data without fetching months when editing inside period view', async () => {
    const store = createStore('edit')
    store.state.tracker.isPeriodView = true
    const { wrapper } = mountEntryForm(store)
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => true)

    await wrapper.vm.submitForm()

    expect(store.dispatch).toHaveBeenCalledWith('tracker/replaceEntry', { id: 2, decimal_time: '1.25', fields: {} })
    expect(store.dispatch).toHaveBeenCalledWith('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'])
    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/fetchMonths')
    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/setSelectedMonthFromRoute')
  })

  it('does not submit when the form is invalid', async () => {
    const { wrapper, store } = mountEntryForm()
    wrapper.vm.$refs.entryForm.reportValidity = vi.fn(() => false)

    await wrapper.vm.submitForm()

    expect(store.dispatch).not.toHaveBeenCalledWith('tracker/submitEntryForm')
  })
})
