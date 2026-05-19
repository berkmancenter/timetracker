import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import Menu from '../Menu.vue'

function mountMenu(options = {}) {
  const emit = vi.fn()
  const wrapper = mount(Menu, {
    props: options.props,
    global: {
      mocks: {
        isTouchDevice: options.isTouchDevice ?? false,
        mitt: { emit },
      },
      stubs: {
        RouterLink: {
          props: ['to'],
          template: '<a class="router-link-stub" :data-route-name="to.name" @click="$emit(\'click\')"><slot /></a>',
        },
      },
    },
  })

  return { wrapper, emit }
}

describe('Menu', () => {
  it('renders the internal and external menu links', () => {
    const { wrapper } = mountMenu({
      props: {
        headerClass: 'header-extra',
        contentClass: 'content-extra',
      },
    })

    expect(wrapper.find('h5').classes()).toContain('header-extra')
    expect(wrapper.find('.content-extra').exists()).toBe(true)
    expect(wrapper.findAll('.router-link-stub').map((link) => link.text())).toEqual(['Time entries', 'Timesheets'])

    const external = wrapper.find('a[target="_blank"]')
    expect(external.text()).toBe('Help')
    expect(external.attributes('href')).toBe('https://berkman-klein-center.gitbook.io/timetracker')
  })

  it('closes the side menu on touch devices when a link is selected', async () => {
    const { wrapper, emit } = mountMenu({ isTouchDevice: true })

    await wrapper.find('.router-link-stub').trigger('click')

    expect(emit).toHaveBeenCalledWith('closeSideMenu')
  })

  it('leaves the side menu open on non-touch devices', async () => {
    const { wrapper, emit } = mountMenu({ isTouchDevice: false })

    await wrapper.find('.router-link-stub').trigger('click')

    expect(emit).not.toHaveBeenCalled()
  })
})
