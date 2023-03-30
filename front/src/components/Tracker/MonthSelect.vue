<template>
  <div class="tracker-months">
    <h5 class="has-text-weight-bold is-size-5 mt-2 sidebar-header">Select Month</h5>

    <div class="select">
      <select v-model="$store.state.tracker.selectedMonth">
        <option value="all">All</option>
        <option v-for="month in $store.state.tracker.months" :key="month" :value="month">
          {{ month }}
        </option>
      </select>
    </div>

    <div class="columns">
      <div class="column">
        <button class="button mt-2" @click="changeMonth">Change</button>
      </div>
      <div class="column">
        <button class="button mt-2" @click="getCsv">CSV</button>
      </div>
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
      changeMonth() {
        this.$router.push(
          {
            name: 'tracker.index',
            params: {
              month: this.$store.state.tracker.selectedMonth
            }
          }
        )

        this.$store.dispatch('tracker/fetchEntries')
        this.$store.dispatch('tracker/fetchDailyTotals')
      },
      getCsv() {
        window.location.href = `${this.apiUrl}/time_entries/entries?csv=true&month=${this.$store.state.tracker.selectedMonth}`
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
</style>
