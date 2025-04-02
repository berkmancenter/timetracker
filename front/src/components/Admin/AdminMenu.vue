<template>
  <div class="admin-menu">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Menu</h5>

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
            label: 'Time entries',
            name: 'tracker.index',
          },
          {
            label: 'Timesheets',
            name: 'timesheets.index',
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
