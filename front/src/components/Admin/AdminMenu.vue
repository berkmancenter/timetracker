<template>
  <div class="admin-menu">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Admin</h5>

    <div class="switmenu-section-content">
      <ul>
        <li v-for="adminMenuItem in adminMenuItems">
          <router-link :to="adminMenuItem" :class="adminMenuItem.class">{{ adminMenuItem.label }}</router-link>
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
            label: 'Exit Admin',
            name: 'tracker.index',
            class: 'admin-menu-item-hidden-active',
          },
          {
            label: 'Timesheets',
            name: 'timesheets.index',
          },
          {
            label: 'Users',
            name: 'users.index',
          },
          {
            label: 'Periods',
            name: 'periods.index',
          },
        ],
      }
    },
  }
</script>

<style lang="scss">
  .router-link-active {
    &.admin-menu-item-hidden-active {
      display: none;
    }
  }
</style>
