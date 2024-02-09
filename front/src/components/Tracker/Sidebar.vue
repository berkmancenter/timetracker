<template>
  <div>
    <timesheet-select></timesheet-select>
    <month-select></month-select>
    <totals v-if="$store.state.tracker.selectedMonth !== 'all'"></totals>
    <daily-totals v-if="$store.state.tracker.selectedMonth !== 'all'"></daily-totals>
    <popular v-if="$store.state.shared.user.sudoMode === false"></popular>
    <admin-menu />
  </div>
</template>

<script>
  import DailyTotals from '@/components/Tracker/DailyTotals.vue'
  import Totals from '@/components/Tracker/Totals.vue'
  import MonthSelect from '@/components/Tracker/MonthSelect.vue'
  import TimesheetSelect from '@/components/Tracker/TimesheetSelect.vue'
  import Popular from '@/components/Tracker/Popular.vue'
  import AdminMenu from '@/components/Admin/AdminMenu.vue'

  export default {
    name: 'Sidebar',
    components: {
      DailyTotals,
      Totals,
      MonthSelect,
      TimesheetSelect,
      Popular,
      AdminMenu,
    },
  }
</script>
