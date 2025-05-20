<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

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
      <ActionButton
        :icon="downloadIcon"
        buttonText="Download CSV"
        @click="getCsv()"
      />
    </div>

    <SuperAdminFilter :users="$store.state.admin.periodStats?.stats" @change="superAdminFilterChanged" />

    <AdminTable :tableClasses="['admin-periods-stats-table']" :forceSortingRefresh="$store.state.admin.periodStats?.period?.custom_fields">
      <thead>
        <tr class="no-select">
          <th class="admin-periods-stats-table-email">Identifier</th>
          <th data-sort-method="number" class="admin-periods-stats-table-narrow-cell">Hours</th>
          <th data-sort-method="number" class="admin-periods-stats-table-narrow-cell">Total hours</th>
          <th data-sort-method="number" class="admin-periods-stats-table-narrow-cell">Should have now</th>
          <th data-sort-method="number" class="admin-periods-stats-table-narrow-cell">Balance</th>
          <th data-sort-method="number" class="admin-periods-stats-table-narrow-cell">Balance percentage</th>
          <th class="admin-periods-stats-table-narrow-cell">Last entry date</th>
          <th v-for="field in customFields"
              :key="field.id"
              class="admin-periods-stats-table-custom-field"
          >
            {{ field.title }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="periodStat in filteredItems" @click="openPeriodUserInTracker(periodStat)">
          <td>{{ getUserIdentifier(periodStat) }}</td>
          <td class="no-break">{{ periodStat.credits }}</td>
          <td class="no-break">{{ periodStat.total_hours }}</td>
          <td class="no-break">{{ periodStat.should_hours }}</td>
          <td class="admin-periods-stats-period-balance no-break" :class="{ 'admin-periods-stats-period-negative-balance': periodStat.balance < 0 }">{{ periodStat.balance }}</td>
          <td class="no-break">{{ periodStat.balance_percent }}</td>
          <td class="no-break">
            <div class="is-hidden">{{ periodStat.last_entry_date }}</div>
            {{ formatLastEntryDate(periodStat.last_entry_date) }}
          </td>
          <td v-for="field in customFields"
              :key="`${periodStat.user_id}-${field.id}`"
              class="no-break"
          >
            {{ getCustomFieldValue(periodStat, field) }}
          </td>
        </tr>
        <tr v-if="filteredItems.length === 0">
          <td :colspan="7 + customFields.length">No records found.</td>
        </tr>
      </tbody>
    </AdminTable>
  </div>
</template>

<script>
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'
  import ActionButton from '@/components/Shared/ActionButton.vue'
  import downloadIcon from '@/images/download_main.svg'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'

  import { formatIsoDateTimeToLocaleString } from '@/lib/date-time.js'
  import { getUserIdentifier } from '@/lib/user.js'

  export default {
    name: 'AdminPeriodsStats',
    components: {
      AdminTable,
      SuperAdminFilter,
      ActionButton,
      Breadcrumbs,
    },
    data() {
      return {
        filteredItems: [],
        apiUrl: import.meta.env.VITE_API_URL,
        downloadIcon,
        formatIsoDateTimeToLocaleString,
        getUserIdentifier,
      }
    },
    computed: {
      breadcrumbs() {
        let breadcrumbs = []

        breadcrumbs.push({
          text: 'Timesheets',
          link: '/admin/timesheets',
        })

        breadcrumbs.push({
          text: this.$store.state.admin?.timesheet?.name,
        })

        breadcrumbs.push({
          text: 'Periods',
          link: `/admin/timesheets/${this.$store.state.admin?.timesheet?.id}/periods`,
        })

        breadcrumbs.push({
          text: this.$store.state.admin.periodStats?.period?.name,
        })

        breadcrumbs.push({
          text: 'Statistics',
        })

        return breadcrumbs
      },
      customFields() {
        return this.$store.state.admin.periodStats?.period?.custom_fields || []
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

        const periodStats = await this.$store.dispatch('admin/fetchPeriodStats', {
          periodId: this.$route.params.id,
          timesheetId: this.$route.params.timesheet_id,
        })
        const timesheet = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.timesheet_id)
        this.$store.dispatch('admin/setTimesheet', timesheet)
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

        window.location.href = `${this.apiUrl}/timesheets/${this.$route.params.timesheet_id}/periods/${this.$route.params.id}/stats?csv=true&user_ids=${usersIds}`
      },
      formatLastEntryDate(inputDate) {
        if (!inputDate) {
          return ''
        }

        const [year, month, day] = inputDate.split('-')
        const outputDate = `${month}/${day}/${year}`

        return outputDate
      },
      getCustomFieldValue(periodStat, field) {
        // Return custom field value using the naming convention
        return periodStat[`custom_field_${field.id}`] || ''
      },
      openPeriodUserInTracker(periodStat) {
        this.$router.push({
          name: 'tracker.period.user',
          params: {
            period_id: this.$route.params.id,
            timesheet: this.$store.state.admin?.timesheet?.uuid,
            user_id: periodStat.user_id,
          },
        })
      },
    },
  }
</script>

<style lang="scss">
  .admin-periods-stats {
    &-period-balance {
      color: #078907;
    }

    &-period-negative-balance {
      color: #db0404;
    }

    &-info {
      span {
        margin-bottom: 1rem;
      }
    }

    &-table {
      &-narrow-cell {
        max-width: 6rem;
      }

      &-email {
        min-width: 10rem;
      }

      &-custom-field {
        min-width: 8rem;
      }

      tbody {
        tr {
          cursor: pointer;
        }
      }
    }
  }
</style>
