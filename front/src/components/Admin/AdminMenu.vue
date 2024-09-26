<template>
  <div class="admin-menu">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Manage</h5>

    <div class="switmenu-section-content">
      <ul>
        <li v-for="adminMenuItem in adminMenuItems">
          <router-link :to="adminMenuItem" :class="adminMenuItem.class" @click="hideMenuMobile">{{ adminMenuItem.label }}</router-link>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'AdminMenu',
    data() {
      return {
        adminMenuItems: [
          {
            label: 'Back to tracking',
            name: 'tracker.index',
            class: 'admin-menu-item-hidden-active',
          },
          {
            label: 'Timesheets',
            name: 'timesheets.index',
          },
          {
            label: 'Periods',
            name: 'periods.index',
          },
        ],
      }
    },
    methods: {
      hideMenuMobile() {
        if (this.isTouchDevice) {
          this.mitt.emit('closeSideMenu')
        }
      },
    },
  }
</script>

<style lang="scss">
  .admin-menu {
    user-select: none;
  }

  .router-link-active {
    &.admin-menu-item-hidden-active {
      display: none;
    }
  }
</style>
