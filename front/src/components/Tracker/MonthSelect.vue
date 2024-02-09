<template>
  <div class="tracker-months" v-if="$store.state.tracker.months.length > 0">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Month</h5>

    <div class="switmenu-section-content">
      <div class="select">
        <select v-model="$store.state.tracker.selectedMonth" @change="changeMonth">
          <option value="all">All</option>
          <option v-for="month in $store.state.tracker.months" :key="month" :value="month">
            {{ month }}
          </option>
        </select>
      </div>

      <button class="button mt-2" @click="getCsv">CSV</button>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'MonthSelect',
    data() {
      return {
        apiUrl: import.meta.env.VITE_API_URL,
      }
    },
    methods: {
      async changeMonth() {
        this.mitt.emit('spinnerStart')

        this.$router.push(
          {
            name: 'tracker.index',
            params: {
              timesheet: this.$store.state.tracker.selectedTimesheet.uuid,
              month: this.$store.state.tracker.selectedMonth,
            }
          }
        )

        await this.$store.dispatch('tracker/reloadViewData', ['entries', 'dailyTotals', 'totals'])

        this.mitt.emit('spinnerStop')
      },
      getCsv() {
        window.location.href = `${this.apiUrl}/time_entries/entries?csv=true&month=${this.$store.state.tracker.selectedMonth}&timesheet_uuid=${this.$store.state.tracker.selectedTimesheet.uuid}`
      },
    },
  };
</script>

<style scoped lang="scss">
  select,
  .select {
    width: 100%;
    text-align: center;
  }

  @media screen and (max-width: 768px) {
    .column:first-child {
      padding-bottom: 0;
    }
    .column:last-child {
      padding-top: 0;
    }
  }
</style>
