<template>
  <div>
    <month-select></month-select>
    <daily-totals v-if="$store.state.tracker.selectedMonth !== 'all'"></daily-totals>
    <popular v-if="$store.state.shared.user.sudoMode === false"></popular>
  </div>
</template>

<script>
  import DailyTotals from '@/components/Tracker/DailyTotals.vue'
  import MonthSelect from '@/components/Tracker/MonthSelect.vue'
  import Popular from '@/components/Tracker/Popular.vue'

  export default {
    name: 'Sidebar',
    components: {
      DailyTotals,
      MonthSelect,
      Popular,
    },
  }
</script>

<style lang="scss"></style>
