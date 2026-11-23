<template>
  <div>
    <router-view v-cloak />
  </div>
</template>

<script>
  export default {
    name: 'Timetracker',
  }
</script>

<style lang="scss">
  @use '@/assets/scss/fonts/fonts.scss';
  @use '@/assets/scss/variables.scss';
  @use '@/assets/scss/bulma-custom.scss';
  @use '@/assets/scss/datepicker-custom.scss';
  @use '@/assets/scss/global.scss';
</style>
