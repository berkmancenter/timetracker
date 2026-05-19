import { mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import Modal from '../Modal.vue'

const modalStub = {
  template: '<div class="vue-final-modal-stub"><slot /></div>',
}

function createMittMock() {
  const handlers = {}

  return {
    handlers,
    on: vi.fn((event, callback) => {
      handlers[event] = callback
    }),
  }
}

function mountModal(options = {}) {
  const mitt = createMittMock()
  const wrapper = mount(Modal, {
    attachTo: document.body,
    props: {
      title: 'Delete entry',
      ...options.props,
    },
    slots: options.slots,
    global: {
      mocks: {
        mitt,
      },
      stubs: {
        VueFinalModal: modalStub,
        Icon: {
          props: ['src'],
          template: '<img class="tracker-icon" :src="src">',
        },
      },
    },
  })

  return { wrapper, mitt }
}

describe('Modal', () => {
  beforeEach(() => {
    document.querySelector('html').style.overflow = ''
  })

  it('renders title, slot content, and default action buttons', () => {
    const { wrapper } = mountModal({
      slots: {
        default: '<p class="modal-body">Are you sure?</p>',
      },
    })

    expect(wrapper.find('.timetracker-modal-title-text').text()).toBe('Delete entry')
    expect(wrapper.find('.modal-body').text()).toBe('Are you sure?')
    expect(wrapper.find('.timetracker-modal-buttons-confirm').text()).toContain('Confirm')
    expect(wrapper.find('.button.ml-2').text()).toBe('Cancel')
  })

  it('emits confirm and cancel events', async () => {
    const { wrapper } = mountModal()

    await wrapper.find('.timetracker-modal-buttons-confirm').trigger('click')
    await wrapper.find('.button.ml-2').trigger('click')
    await wrapper.find('.timetracker-modal-title-close').trigger('click')

    expect(wrapper.emitted('confirm')).toHaveLength(1)
    expect(wrapper.emitted('cancel')).toHaveLength(2)
  })

  it('can hide action buttons', () => {
    const { wrapper } = mountModal({
      props: {
        showConfirmButton: false,
        showCancelButton: false,
      },
    })

    expect(wrapper.find('.timetracker-modal-buttons-confirm').exists()).toBe(false)
    expect(wrapper.find('.button.ml-2').exists()).toBe(false)
  })

  it('tracks working state from mitt events', async () => {
    const { wrapper, mitt } = mountModal()

    mitt.handlers.modalIsWorking()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.timetracker-modal-buttons-confirm').classes()).toContain('running')

    mitt.handlers.modalIsNotWorking()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.timetracker-modal-buttons-confirm').classes()).not.toContain('running')
  })

  it('locks page scroll when opened and restores it when closed', async () => {
    const { wrapper } = mountModal()

    wrapper.vm.opened()
    await wrapper.vm.$nextTick()
    expect(document.querySelector('html').style.overflow).toBe('hidden')
    expect(document.activeElement).toBe(wrapper.find('.timetracker-modal-buttons-confirm').element)

    wrapper.vm.closed()
    expect(document.querySelector('html').style.overflow).toBe('auto')
  })
})
