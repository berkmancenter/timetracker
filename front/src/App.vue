<template>
  <div>
    <router-view v-cloak />
  </div>
</template>

<script>
  export default {
    name: 'app'
  }
</script>

<style lang="scss">
  @import '@/scss/variables.scss';
  @import '@/scss/bulma-custom.scss';
  @import '@/scss/datepicker-custom.scss';
</style>
