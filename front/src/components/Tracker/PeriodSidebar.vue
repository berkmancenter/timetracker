<template>
  <div>
    <main-menu
      header-class="sidebar-section-header"
      content-class="sidebar-section-content"
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
  }
</script>
