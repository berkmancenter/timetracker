<template>
  <div class="tracker-tools" v-if="$store.state.tracker.months.length > 0">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Tools</h5>

    <div class="switmenu-section-content">
      <button class="tracker-tools-csv button" @click="getCsv" title="Click to download CSV of entries from the currently selected month.">
        <img :src="csvIcon" />
      </button>
    </div>
  </div>
</template>

<script>
  import csvIcon from '@/images/csv.svg'

  export default {
    name: 'Tools',
    data() {
      return {
        apiUrl: import.meta.env.VITE_API_URL,
        csvIcon,
      }
    },
    methods: {
      getCsv() {
        window.location.href = `${this.apiUrl}/time_entries/entries?csv=true&month=${this.$store.state.tracker.selectedMonth}&timesheet_uuid=${this.$store.state.tracker.selectedTimesheet.uuid}`
      },
    },
  };
</script>

<style lang="scss">
  .tracker-tools {
    &-csv {
      padding-left: 0.5rem;
      padding: 0.5rem;

      img {
        width: 2rem;
      }
    }
  }
</style>
