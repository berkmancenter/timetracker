<template>
  <div>
    <main-menu
      header-class="switmenu-section-header"
      content-class="switmenu-section-content"
    />
    <totals></totals>
    <period-totals></period-totals>
  </div>
</template>

<script>
  import periodTotals from '@/components/Tracker/PeriodTotals.vue'
  import Totals from '@/components/Tracker/Totals.vue'
  import MainMenu from '@/components/Shared/Menu.vue'

  export default {
    name: 'PeriodSidebar',
    components: {
      periodTotals,
      Totals,
      MainMenu,
    },
    mounted() {
      document.body.classList.add('tracker-entries')
    },
    beforeUnmount() {
      document.body.classList.remove('tracker-entries')
    }
  }
</script>

<style lang="scss">
  .tracker-entries {
    .timetracker-menu {
      @media all and (min-width: 701px) {
        display: none;
      }
    }
  }
</style>
