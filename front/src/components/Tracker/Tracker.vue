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
    name: 'TrackerLayout',
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

        const months = await this.$store.dispatch('tracker/fetchMonths')
        this.$store.dispatch('tracker/setMonths', months)

        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'entries', 'dailyTotals', 'totals'])
        this.redirectToSelectedMonth(this.$store)

        this.mitt.emit('spinnerStop')
      },
    },
  }
</script>
