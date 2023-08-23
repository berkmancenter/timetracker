<template>
  <div>
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Admin</h5>

    <div class="switmenu-section-content">
      <ul>
        <li v-for="topMenuItem in topMenuItems">
          <router-link :to="topMenuItem">{{ topMenuItem.label }}</router-link>
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
        topMenuItems: [
          {
            label: 'Timetracker',
            name: 'tracker.index',
          },
          {
            label: 'Workspaces',
            name: 'workspaces.index',
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
