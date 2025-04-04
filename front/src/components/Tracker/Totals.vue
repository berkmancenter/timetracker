<template>
  <div>
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Totals</h5>

    <div class="switmenu-section-content">
      <div class="tracker-totals">
        <table class="table">
          <tbody>
            <tr>
              <th colspan="2">Current timesheet</th>
            </tr>
            <tr>
              <td>Total hours</td>
              <td class="tracker-totals-number-cell">{{ $store.state.tracker.totalCurrentTimesheet }}</td>
            </tr>
            <tr v-if="$store.state.tracker.selectedMonth !== 'all'">
              <td>Total hours in current month</td>
              <td class="tracker-totals-number-cell">{{ $store.state.tracker.totalCurrentMonth }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'Totals',
    data() {
      return {
        apiUrl: import.meta.env.VITE_API_URL,
      }
    },
  };
</script>

<style lang="scss">
  .tracker-totals {
    background-color: #ffffff;

    &-number-cell {
      width: 4rem;
      text-align: right !important;
    }
  }
</style>
