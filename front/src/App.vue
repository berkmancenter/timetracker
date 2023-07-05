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
  @import '@/assets/scss/fonts/fonts.scss';
  @import '@/assets/scss/variables.scss';
  @import '@/assets/scss/bulma-custom.scss';
  @import '@/assets/scss/datepicker-custom.scss';
  @import '@/assets/scss/global.scss';
</style>
