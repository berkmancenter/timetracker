<template>
  <div v-if="$store.state.tracker.selectedMonth !== 'all'">
    <h5 class="has-text-weight-bold is-size-5 mt-2 sidebar-header">Daily Totals</h5>
    <table class="table">
      <tbody>
        <tr v-for="(item, index) in $store.state.tracker.dailyTotals.daily_totals" :key="index">
          <td>{{ item.entry_date }}</td>
          <td>{{ item.total_hours }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
  export default {
    name: 'DailyTotals',
  }
</script>

<style scoped lang="scss">

</style>
