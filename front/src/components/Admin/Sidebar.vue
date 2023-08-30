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
  }
</script>
