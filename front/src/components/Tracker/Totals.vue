<template>
  <div>
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Totals</h5>

    <div class="switmenu-section-content">
      <div class="tracker-totals">
        <div class="mb-1">
          <div class="has-text-weight-bold">Total hours this timesheet</div>
          <span class="tag is-light">{{ $store.state.tracker.totalCurrentTimesheet }}</span>
        </div>

        <div class="mb-1">
          <div class="has-text-weight-bold">Total hours this month</div>
          <span class="tag is-light">{{ $store.state.tracker.totalCurrentMonth }}</span>
        </div>
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

<style scoped lang="scss">
  .tracker-totals {
    background-color: #ffffff;
    padding: 0.25rem;
  }
</style>
