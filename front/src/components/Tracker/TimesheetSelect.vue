<template>
  <div class="tracker-timesheets">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Timesheet</h5>

    <div class="switmenu-section-content">
      <div class="select">
        <select ref="timesheetsSelect" v-model="selectedTimesheet" @change="changeTimesheet($event)">
          <option v-for="timesheet in timesheets" :key="timesheet.id" :value="timesheet.id">
            {{ timesheet.name }}
          </option>
        </select>
      </div>
    </div>
  </div>
</template>

<script>
  import { redirectToSelectedMonth } from '@/router/index'
  import orderBy from 'lodash/orderBy'

  export default {
    name: 'TimesheetSelect',
    data() {
      return {
        apiUrl: import.meta.env.VITE_API_URL,
        selectedTimesheet: null,
        redirectToSelectedMonth: redirectToSelectedMonth,
      }
    },
    computed: {
      timesheets() {
        return orderBy(this.$store.state.tracker.timesheets, ['name'], ['asc'])
      },
    },
    mounted() {
      if (this.$store.state.tracker.selectedTimesheet?.id) {
        this.selectedTimesheet = this.$store.state.tracker.selectedTimesheet.id
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
        this.$store.dispatch('tracker/setSelectedMonthFromRoute')

        this.redirectToSelectedMonth(this.$store)

        await this.$store.dispatch('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'])

        this.mitt.emit('spinnerStop')
      },
    },
    watch: {
      '$store.state.tracker.selectedTimesheet': function() {
        this.selectedTimesheet = this.$store.state.tracker.selectedTimesheet.id
      }
    },
  };
</script>

<style lang="scss">
  .tracker-timesheets {
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
  }
</style>
