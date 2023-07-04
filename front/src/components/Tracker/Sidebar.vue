<template>
  <div>
    <month-select></month-select>
    <daily-totals v-if="$store.state.tracker.selectedMonth !== 'all'"></daily-totals>
    <popular v-if="$store.state.shared.user.sudoMode === false"></popular>
    <admin-menu v-if="$store.state.shared.user.is_admin" />
  </div>
</template>

<script>
  import DailyTotals from '@/components/Tracker/DailyTotals.vue'
  import MonthSelect from '@/components/Tracker/MonthSelect.vue'
  import Popular from '@/components/Tracker/Popular.vue'
  import AdminMenu from '@/components/Admin/AdminMenu.vue'

  export default {
    name: 'Sidebar',
    components: {
      DailyTotals,
      MonthSelect,
      Popular,
      AdminMenu,
    },
  }
</script>
