<template>
  <div class="tracker-timesheets">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Timesheet</h5>

    <div class="switmenu-section-content">
      <div class="select">
        <select v-model="$store.state.tracker.selectedTimesheet" @change="changeTimesheet">
          <option v-for="timesheet in $store.state.tracker.timesheets" :key="timesheet.id" :value="timesheet">
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
        redirectToSelectedMonth: redirectToSelectedMonth,
      }
    },
    methods: {
      async changeTimesheet() {
        this.mitt.emit('spinnerStart')

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
