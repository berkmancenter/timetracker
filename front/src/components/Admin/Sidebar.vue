<template>
  <div>
    <admin-menu />
  </div>
</template>

<script>
  import AdminMenu from '@/components/Admin/AdminMenu.vue'

  export default {
    name: 'AdminSidebar',
    components: {
      AdminMenu,
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
      width: 200px;
    }
  }

  .switmenu-html-open {
    .tracker-admin {
      .switmenu-menu {
        width: 200px;

        @media all and (max-width: 700px) { width: 100%; }
      }

      .switmenu-content {
        margin-left: calc(200px + 1rem);

        @media all and (max-width: 1600px) { margin-left: calc(200px + 1rem); }
        @media all and (max-width: 1300px) { margin-left: calc(200px + 1rem); }
        @media all and (max-width: 900px) { margin-left: calc(200px + 1rem); }
        @media all and (max-width: 700px) { margin-left: 100%; }
      }
    }
  }
</style>
