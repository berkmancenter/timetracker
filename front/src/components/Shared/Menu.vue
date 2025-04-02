<template>
  <div class="timetracker-menu">
    <h5 :class="['has-text-weight-bold is-size-5 mt-2', headerClass]">Menu</h5>

    <div :class="[contentClass]">
      <ul>
        <li v-for="menuItem in menuItems">
          <router-link v-if="!menuItem.external" :to="menuItem" :class="menuItem.class" @click="hideMenuMobile">{{ menuItem.label }}</router-link>
          <a v-if="menuItem.external" :href="menuItem.link" :class="menuItem.class" @click="hideMenuMobile" target="_blank">{{ menuItem.label }}</a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'Menu',
    props: {
      headerClass: {
        type: String,
        required: false,
        default: '',
      },
      contentClass: {
        type: String,
        required: false,
        default: '',
      },
      showHeader: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    data() {
      return {
        menuItems: [
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
  .timetracker-menu {
    user-select: none;
  }

  .router-link-active {
    &.timetracker-menu-item-hidden-active {
      display: none;
    }
  }
</style>
