<template>
  <div class="tracker-timesheets">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Timesheet</h5>

    <div class="switmenu-section-content">
      <div class="select">
        <select ref="timesheetsSelect" v-model="selectedMonth" @change="changeTimesheet($event)">
          <option v-for="timesheet in $store.state.tracker.timesheets" :key="timesheet.id" :value="timesheet.id">
            {{ timesheet.name }}
          </option>
        </select>
      </div>
    </div>
  </div>
</template>

<script>
  import { redirectToSelectedMonth } from '@/router/index'

  export default {
    name: 'TimesheetSelect',
    data() {
      return {
        apiUrl: import.meta.env.VITE_API_URL,
        selectedMonth: null,
        redirectToSelectedMonth: redirectToSelectedMonth,
      }
    },
    mounted() {
      if (this.$store.state.tracker.selectedTimesheet?.id) {
        this.selectedMonth = this.$store.state.tracker.selectedTimesheet.id
      }
    },
    methods: {
      async changeTimesheet(ev) {
        this.mitt.emit('spinnerStart')

        const selectedTimesheet = this.$store.state.tracker.timesheets.find(timesheet => timesheet.id == ev.target.value)

        this.$store.dispatch('tracker/setSelectedTimesheet', selectedTimesheet)

        this.$router.push(
          {
            name: 'tracker.index',
            params: {
              timesheet: this.$store.state.tracker.selectedTimesheet.uuid,
              month: null,
            }
          }
        )

        const months = await this.$store.dispatch('tracker/fetchMonths')
        this.$store.dispatch('tracker/setMonths', months)

        this.redirectToSelectedMonth(this.$store)

        await this.$store.dispatch('tracker/reloadViewData', ['entries', 'dailyTotals'])

        this.mitt.emit('spinnerStop')
      },
    },
    watch: {
      '$store.state.tracker.selectedTimesheet': function() {
        this.selectedMonth = this.$store.state.tracker.selectedTimesheet.id
      }
    },
  };
</script>

<style scoped lang="scss">
  select,
  .select {
    width: 100%;
    text-align: center;
  }

  button {
    width: 100%;
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
