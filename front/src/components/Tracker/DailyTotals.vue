<template>
  <div class="tracker-daily-totals" v-if="$store.state.tracker.dailyTotals.length > 0">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Daily Totals</h5>

    <div class="switmenu-section-content">
      <table class="table">
        <thead>
          <tr>
            <th>Day</th>
            <th>Hours</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="(item, index) in $store.state.tracker.dailyTotals" :key="index">
            <tr>
              <td>{{ item.entry_date }}</td>
              <td>{{ item.total_hours }}</td>
            </tr>
            <tr v-if="$store.state.shared.user.sudoMode">
              <td colspan="2">{{ cleanUsername(item.username) }}</td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
  import cleanUsername from '@/lib/clean-username'

  export default {
    name: 'DailyTotals',
    data() {
      return {
        cleanUsername,
      }
    },
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
