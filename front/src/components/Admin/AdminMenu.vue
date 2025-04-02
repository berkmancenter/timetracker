<template>
  <div class="admin-menu">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Menu</h5>

    <div class="switmenu-section-content">
      <ul>
        <li v-for="adminMenuItem in adminMenuItems">
          <router-link v-if="!adminMenuItem.external" :to="adminMenuItem" :class="adminMenuItem.class" @click="hideMenuMobile">{{ adminMenuItem.label }}</router-link>
          <a v-if="adminMenuItem.external" :href="adminMenuItem.link" :class="adminMenuItem.class" @click="hideMenuMobile" target="_blank">{{ adminMenuItem.label }}</a>
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
          {
            label: 'Help',
            external: true,
            link: 'https://berkman-klein-center.gitbook.io/timetracker',
          }
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
