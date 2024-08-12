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
              <td>{{ $store.state.tracker.totalCurrentTimesheet }}</td>
            </tr>
            <tr v-if="$store.state.tracker.selectedMonth !== 'all'">
              <td>Total hours in current month</td>
              <td>{{ $store.state.tracker.totalCurrentMonth }}</td>
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
    padding: 0.25rem;
  }
</style>
