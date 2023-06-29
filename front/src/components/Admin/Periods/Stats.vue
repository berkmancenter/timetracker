<template>
  <div class="content admin-periods-stats">
    <h1 class="is-size-1">Statistics</h1>

    <h3 class="is-size-4">
      for
      <span class="tag is-black is-large">{{ $store.state.admin.periodStats?.period?.name }}</span>
      from
      <span class="tag is-black is-large">{{ $store.state.admin.periodStats?.period?.from }}</span>
      to
      <span class="tag is-black is-large">{{ $store.state.admin.periodStats?.period?.to }}</span>
    </h3>

    <admin-table :tableClasses="['admin-periods-stats-table']">
      <thead>
        <tr class="no-select">
          <th>Username</th>
          <th>Email</th>
          <th>Credits</th>
          <th>Total hours</th>
          <th>Should have now</th>
          <th>Balance</th>
          <th>Balance percentage</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="periodStat in $store.state.admin.periodStats?.stats">
          <td>{{ cleanUsername(periodStat.username) }}</td>
          <td>{{ periodStat.email }}</td>
          <td>{{ periodStat.credits }}</td>
          <td>{{ periodStat.total_hours }}</td>
          <td>{{ periodStat.should_hours.toFixed(2) }}</td>
          <td class="admin-periods-stats-period-balance" :class="{ 'admin-periods-stats-period-negative-balance': periodStat.balance < 0 }">{{ periodStat.balance.toFixed(2) }}</td>
          <td>{{ periodStat.balance_percent.toFixed(2) }}</td>
        </tr>
        <tr v-if="$store.state.admin.periodStats?.stats?.length === 0">
          <td colspan="7">No records found.</td>
        </tr>
      </tbody>
    </admin-table>
  </div>
</template>

<script>
  import cleanUsername from '@/lib/clean-username'
  import AdminTable from '@/components/Admin/AdminTable.vue'

  export default {
    name: 'AdminPeriodsStats',
    components: {
      AdminTable,
    },
    data() {
      return {
        cleanUsername: cleanUsername,
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      initialDataLoad() {
        this.loadStats()
      },
      async loadStats() {
        const periodStats = await this.$store.dispatch('admin/fetchPeriodStats', this.$route.params.id)

        this.$store.dispatch('admin/setPeriodStats', periodStats)
      },
    },
  }
</script>

<style lang="scss">
  @import '@/assets/scss/admin-table.scss';

  .admin-periods-stats {
    .admin-periods-stats-period-balance {
      color: #078907;

      &.admin-periods-stats-period-negative-balance {
        color: #db0404;
      }
    }
  }
</style>
