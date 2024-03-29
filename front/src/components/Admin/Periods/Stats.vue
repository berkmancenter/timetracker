<template>
  <div class="content admin-periods-stats">
    <h4 class="is-size-4">Statistics</h4>

    <div class="admin-periods-stats-info mb-2">
      for
      <span class="tag is-black is-medium">{{ $store.state.admin.periodStats?.period?.name }}</span>
      from
      <span class="tag is-black is-medium">{{ $store.state.admin.periodStats?.period?.from }}</span>
      to
      <span class="tag is-black is-medium">{{ $store.state.admin.periodStats?.period?.to }}</span>
    </div>

    <div class="mb-4">
      <a class="button is-info" @click="getCsv()">Download CSV</a>
    </div>

    <super-admin-filter :users="$store.state.admin.periodStats?.stats" @change="superAdminFilterChanged" />

    <admin-table :tableClasses="['admin-periods-stats-table']">
      <thead>
        <tr class="no-select">
          <th class="admin-periods-stats-table-email">Email</th>
          <th class="admin-periods-stats-table-narrow-cell">Hours</th>
          <th class="admin-periods-stats-table-narrow-cell">Total hours</th>
          <th class="admin-periods-stats-table-narrow-cell">Should have now</th>
          <th class="admin-periods-stats-table-narrow-cell">Balance</th>
          <th class="admin-periods-stats-table-narrow-cell">Balance percentage</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="periodStat in filteredItems">
          <td>{{ periodStat.email }}</td>
          <td class="no-break">{{ periodStat.credits }}</td>
          <td class="no-break">{{ periodStat.total_hours }}</td>
          <td class="no-break">{{ periodStat.should_hours }}</td>
          <td class="admin-periods-stats-period-balance no-break" :class="{ 'admin-periods-stats-period-negative-balance': periodStat.balance < 0 }">{{ periodStat.balance }}</td>
          <td class="no-break">{{ periodStat.balance_percent }}</td>
        </tr>
        <tr v-if="filteredItems.length === 0">
          <td colspan="7">No records found.</td>
        </tr>
      </tbody>
    </admin-table>
  </div>
</template>

<script>
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
        this.mitt.emit('spinnerStart')

        const periodStats = await this.$store.dispatch('admin/fetchPeriodStats', this.$route.params.id)

        this.$store.dispatch('admin/setPeriodStats', periodStats)

        this.mitt.emit('spinnerStop')
      },
      superAdminFilterChanged(users) {
        this.filteredItems = users
      },
      getCsv() {
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

    .admin-periods-stats-info {
      span {
        margin-bottom: 1rem;
      }
    }

    .admin-periods-stats-table-narrow-cell {
      max-width: 6rem;
    }

    .admin-periods-stats-table-email {
      min-width: 10rem;
    }
  }
</style>
