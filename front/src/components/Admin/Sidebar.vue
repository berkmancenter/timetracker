<template>
  <div>
    <admin-menu v-if="$store.state.shared.user.is_admin" />
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

<style lang="scss"></style>
