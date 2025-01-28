<template>
  <div>
    <timesheet-select></timesheet-select>
    <popular v-if="$store.state.shared.user.sudoMode === false"></popular>
    <month-select></month-select>
    <totals></totals>
    <period-totals></period-totals>
    <admin-menu />
  </div>
</template>

<script>
  import periodTotals from '@/components/Tracker/PeriodTotals.vue'
  import Totals from '@/components/Tracker/Totals.vue'
  import MonthSelect from '@/components/Tracker/MonthSelect.vue'
  import TimesheetSelect from '@/components/Tracker/TimesheetSelect.vue'
  import Popular from '@/components/Tracker/Popular.vue'
  import AdminMenu from '@/components/Admin/AdminMenu.vue'

  export default {
    name: 'Sidebar',
    components: {
      periodTotals,
      Totals,
      MonthSelect,
      TimesheetSelect,
      Popular,
      AdminMenu,
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
    .admin-menu {
      @media all and (min-width: 701px) {
        display: none;
      }
    }
  }
</style>
