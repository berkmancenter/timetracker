<template>
  <div class="tracker-daily-totals">
    <h5 class="has-text-weight-bold is-size-5 mt-2 sidebar-header">Daily Totals</h5>
    <table class="table">
      <tbody>
        <tr v-for="(item, index) in $store.state.tracker.dailyTotals" :key="index">
          <td>{{ item.entry_date }}</td>
          <td>{{ item.total_hours }}</td>
          <td v-if="$store.state.tracker.user.sudoMode">{{ item.username }}</td>
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

<style lang="scss">
  .tracker-daily-totals {
    td {
      word-break: break-word;
      vertical-align: middle;
    }
  }
</style>
