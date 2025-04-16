<template>
  <div>
    <main-menu
      header-class="switmenu-section-header"
      content-class="switmenu-section-content"
    />
    <timesheet-select></timesheet-select>
    <popular v-if="$store.state.shared.user.sudoMode === false"></popular>
    <totals></totals>
    <period-totals></period-totals>
  </div>
</template>

<script>
  import periodTotals from '@/components/Tracker/PeriodTotals.vue'
  import Totals from '@/components/Tracker/Totals.vue'
  import TimesheetSelect from '@/components/Tracker/TimesheetSelect.vue'
  import Popular from '@/components/Tracker/Popular.vue'
  import MainMenu from '@/components/Shared/Menu.vue'

  export default {
    name: 'Sidebar',
    components: {
      periodTotals,
      Totals,
      TimesheetSelect,
      Popular,
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
