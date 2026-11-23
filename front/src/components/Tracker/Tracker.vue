<template>
  <div>
    <entry-form v-if="$store.state.tracker.selectedTimesheet.uuid"></entry-form>
    <entries v-if="$store.state.tracker.selectedTimesheet.uuid"></entries>
    <div v-if="!$store.state.tracker.selectedTimesheet.uuid">
      Select a timesheet or create new to add new entries.
    </div>
  </div>
</template>

<script>
  import EntryForm from './EntryForm.vue'
  import Entries from './Entries.vue'
  import { redirectToSelectedMonth } from '@/router/index'

  export default {
    name: 'Tracker',
    components: {
      EntryForm,
      Entries,
    },
    data() {
      return {
        redirectToSelectedMonth,
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      async initialDataLoad() {
        this.mitt.emit('spinnerStart')

        const timesheets = await this.$store.dispatch('tracker/fetchTimesheets')
        this.$store.dispatch('tracker/setTimesheets', timesheets)

        if (timesheets.length === 0) {
          this.mitt.emit('spinnerStop')
          this.redirectToSelectedMonth(this.$store)

          return
        }

        this.$store.dispatch('tracker/setSelectedTimesheetFromRoute')

        const months = await this.$store.dispatch('tracker/fetchMonths')
        this.$store.dispatch('tracker/setMonths', months)

        this.$store.dispatch('tracker/setSelectedMonthFromRoute')

        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'entries', 'periodTotals', 'totals', 'users'])
        this.redirectToSelectedMonth(this.$store)

        this.mitt.emit('spinnerStop')
      },
    },
    watch: {
      '$route.params': {
        handler: async function (to, from) {
          if (Object.keys(from).length > 0) {
            const timesheetAlreadySelected = this.$store.state.tracker.selectedTimesheet.uuid === to.timesheet
            this.$store.dispatch('tracker/setSelectedTimesheetFromRoute')

            // Months are different for every timesheet, so load them again when the
            // timesheet changed through navigation such as the browser back button.
            // TimesheetSelect already loads them when it changes the selected store value.
            if (to.timesheet !== from.timesheet && !timesheetAlreadySelected) {
              const months = await this.$store.dispatch('tracker/fetchMonths')
              this.$store.dispatch('tracker/setMonths', months)
            }

            this.$store.dispatch('tracker/setSelectedMonthFromRoute')
            await this.$store.dispatch('tracker/reloadViewData', ['entries', 'periodTotals', 'totals', 'users'])
          }
        },
        deep: true,
      }
    }
  }
</script>
