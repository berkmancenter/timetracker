<template>
  <div>
    <main-menu
      header-class="switmenu-section-header"
      content-class="switmenu-section-content"
    />
  </div>
</template>

<script>
  import MainMenu from '@/components/Shared/Menu.vue'

  export default {
    name: 'AdminSidebar',
    components: {
      MainMenu,
    },
    mounted() {
      document.body.classList.add('tracker-admin')
    },
    beforeUnmount() {
      document.body.classList.remove('tracker-admin')
    }
  }
</script>

<style lang="scss">
  .tracker-admin {
    .switmenu-menu {
      width: 0;
    }
  }

  .switmenu-html-open {
    .tracker-admin {
      .switmenu-menu {
        width: 0;

        @media all and (max-width: 700px) { width: 100%; }
      }

      .switmenu-content {
        margin-left: 1rem;
      }
    }
  }
</style>
