<template>
  <div>
    <entry-form></entry-form>
    <entries></entries>
  </div>
</template>

<script>
  import EntryForm from './EntryForm.vue'
  import Entries from './Entries.vue'

  export default {
    name: 'TrackerLayout',
    components: {
      EntryForm,
      Entries,
    },
    data() {
      return {}
    },
    created() {
      this.initialDataLoad()
    },
    updated() {
      this.redirectToSelectedMonth()
    },
    methods: {
      async initialDataLoad() {
        const months = await this.$store.dispatch('tracker/fetchMonths')

        this.$store.dispatch('tracker/setMonths', months)
        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'entries', 'dailyTotals'])
        this.redirectToSelectedMonth()
      },
      redirectToSelectedMonth() {
        this.$router.push(
          {
            name: 'tracker.index',
            params: {
              month: this.$store.state.tracker.selectedMonth,
            },
          },
        )
      },
    },
  }
</script>

<style lang="scss"></style>
