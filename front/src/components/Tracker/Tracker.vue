<template>
  <div>
    <entry-form></entry-form>
    <entries></entries>
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

        const months = await this.$store.dispatch('tracker/fetchMonths')
        this.$store.dispatch('tracker/setMonths', months)

        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'entries', 'dailyTotals'])
        this.redirectToSelectedMonth(this.$store)

        this.mitt.emit('spinnerStop')
      },
    },
  }
</script>
