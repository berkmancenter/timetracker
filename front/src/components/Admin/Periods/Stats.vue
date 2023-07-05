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

    <div class="mb-4">
      <a class="button is-info" @click="getCsv()">Download CSV</a>
    </div>

    <super-admin-filter :users="$store.state.admin.periodStats?.stats" @change="superAdminFilterChanged" />

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
        <tr v-for="periodStat in filteredItems">
          <td>{{ cleanUsername(periodStat.username) }}</td>
          <td>{{ periodStat.email }}</td>
          <td>{{ periodStat.credits }}</td>
          <td>{{ periodStat.total_hours }}</td>
          <td>{{ periodStat.should_hours }}</td>
          <td class="admin-periods-stats-period-balance" :class="{ 'admin-periods-stats-period-negative-balance': periodStat.balance < 0 }">{{ periodStat.balance }}</td>
          <td>{{ periodStat.balance_percent }}</td>
        </tr>
        <tr v-if="filteredItems.length === 0">
          <td colspan="7">No records found.</td>
        </tr>
      </tbody>
    </admin-table>
  </div>
</template>

<script>
  import cleanUsername from '@/lib/clean-username'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'

  export default {
    name: 'AdminPeriodsStats',
    components: {
      AdminTable,
      SuperAdminFilter,
    },
    data() {
      return {
        cleanUsername: cleanUsername,
        filteredItems: [],
        apiUrl: import.meta.env.VITE_API_URL,
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
      superAdminFilterChanged(users) {
        this.filteredItems = users
      },
      getCsv() {
        console.log(this.filteredItems)
        const usersIds = this.filteredItems
          .map(user => user.user_id)
          .join(',')

        window.location.href = `${this.apiUrl}/periods/${this.$route.params.id}/stats?csv=true&user_ids=${usersIds}`
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
