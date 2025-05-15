<template>
  <div class="tracker-period">
    <div class="tracker-period-notification notification">
      You are viewing time entries for the selected timesheet period and user.

      <div>
        <table>
          <tbody>
            <tr>
              <th>Timesheet</th>
              <th>Period</th>
              <th>User</th>
              <th>From</th>
              <th>To</th>
            </tr>
            <tr>
              <td>{{ $store.state.tracker.period?.timesheet?.name }}</td>
              <td>{{ $store.state.tracker.period?.name }}</td>
              <td>{{ $store.state.tracker.periodUser?.email }}</td>
              <td>{{ $store.state.tracker.period?.from }}</td>
              <td>{{ $store.state.tracker.period?.to }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <router-link :to="periodStatsRoute" v-if="periodStatsRoute">Go back to list period stats</router-link>
    </div>

    <entries
      v-if="$store.state.tracker.selectedTimesheet.uuid"
      :periodsView="true"
    ></entries>
  </div>
</template>

<script>
  import Entries from './Entries.vue'

  export default {
    name: 'TrackerPeriod',
    components: {
      Entries,
    },
    data() {
      return {}
    },
    computed: {
      periodStatsRoute() {
        const timesheetId = this.$store.state.tracker?.selectedTimesheet?.id
        const periodId = this.$store.state.tracker?.period?.id

        if (timesheetId && periodId) {
          return { name: 'periods.stats', params: { timesheet_id: timesheetId, id: periodId } }
        }

        return null
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      async initialDataLoad() {
        this.$store.dispatch('tracker/setPeriodView', true)

        this.mitt.emit('spinnerStart')

        const timesheets = await this.$store.dispatch('tracker/fetchTimesheets')
        this.$store.dispatch('tracker/setTimesheets', timesheets)
        this.$store.dispatch('tracker/setSelectedTimesheetFromRoute')

        const period = await this.$store.dispatch('admin/fetchPeriod', {
          timesheetId: this.$route.params.timesheet,
          periodId: this.$route.params.period_id,
        })
        this.$store.dispatch('tracker/setPeriod', period)

        const user = await this.$store.dispatch('tracker/fetchUser', this.$route.params.user_id)
        this.$store.dispatch('tracker/setPeriodUser', user)

        await this.$store.dispatch('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'], this.$route.params.period_id)

        this.mitt.emit('spinnerStop')
      },
    },
    unmounted() {
      this.$store.dispatch('tracker/setPeriodView', false)
      this.$store.dispatch('tracker/setPeriodUser', null)
    },
  }
</script>

<style lang="scss">
  .tracker-period {
    &-notification {
      table {
        td {
          word-break: break-word;
        }
      }
    }
  }
</style>
