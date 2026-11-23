<template>
  <div>
    <main-menu
      header-class="sidebar-section-header"
      content-class="sidebar-section-content"
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
  }
</script>
