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

      <ActionButton
        class="ml-2"
        :icon="filterIcon"
        buttonText="Filter list"
        @click="openFilterModal()"
      />
    </div>

    <SuperAdminFilter :users="$store.state.admin.periodStats?.stats" @change="superAdminFilterChanged" />

    <AdminTable :tableClasses="['admin-periods-stats-table']">
      <thead>
        <tr class="no-select">
          <th class="admin-periods-stats-table-email admin-table-sortable" :aria-sort="ariaSortFor('identifier')" @click="sortBy('identifier')">Identifier</th>
          <th class="admin-table-sortable" :aria-sort="ariaSortFor('credits')" @click="sortBy('credits')">Hours</th>
          <th class="admin-table-sortable" :aria-sort="ariaSortFor('total_hours')" @click="sortBy('total_hours')">Total hours</th>
          <th class="admin-table-sortable" :aria-sort="ariaSortFor('should_hours')" @click="sortBy('should_hours')">Should have now</th>
          <th class="admin-table-sortable" :aria-sort="ariaSortFor('balance')" @click="sortBy('balance')">Balance</th>
          <th class="admin-table-sortable" :aria-sort="ariaSortFor('balance_percent')" @click="sortBy('balance_percent')">Balance percentage</th>
          <th class="admin-table-sortable" :aria-sort="ariaSortFor('last_entry_date')" @click="sortBy('last_entry_date')">Last entry date</th>
          <th v-for="field in customFields"
              :key="field.id"
              class="admin-periods-stats-table-custom-field admin-table-sortable"
              :aria-sort="ariaSortFor(`custom_field_${field.id}`)"
              @click="sortBy(`custom_field_${field.id}`)"
          >
            {{ field.title }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="periodStat in sortedItems" :key="periodStat.user_id" @click="openPeriodUserInTracker(periodStat)">
          <td>{{ getUserIdentifier(periodStat) }}</td>
          <td class="no-break">{{ periodStat.credits }}</td>
          <td class="no-break">{{ periodStat.total_hours }}</td>
          <td class="no-break">{{ periodStat.should_hours }}</td>
          <td class="admin-periods-stats-period-balance no-break" :class="{ 'admin-periods-stats-period-negative-balance': Number(periodStat.balance) < 0 }">{{ periodStat.balance }}</td>
          <td class="no-break">{{ periodStat.balance_percent }}</td>
          <td class="no-break">{{ formatLastEntryDate(periodStat.last_entry_date) }}</td>
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

  <FilterModal
    v-model="showFilterModal"
    :customFields="customFields"
    :periodStats="$store.state.admin.periodStats?.stats || []"
    @filter-applied="applyFilters"
  ></FilterModal>
</template>

<script>
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'
  import ActionButton from '@/components/Shared/ActionButton.vue'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'
  import FilterModal from '@/components/Admin/Timesheets/Periods/StatsFilters.vue'

  import filterIcon from '@/images/filters.svg'
  import downloadIcon from '@/images/download_main.svg'

  import { ariaSort, nextSortState, sortRows } from '@/lib/table-sort.js'
  import { getUserIdentifier } from '@/lib/user.js'

  const NUMERIC_SORT_KEYS = new Set([
    'credits',
    'total_hours',
    'should_hours',
    'balance',
    'balance_percent',
  ])

  export default {
    name: 'AdminPeriodsStats',
    components: {
      AdminTable,
      SuperAdminFilter,
      ActionButton,
      Breadcrumbs,
      FilterModal,
    },
    data() {
      return {
        // Rows of the selected Users/Admins/All tab
        roleFilteredItems: [],
        // Rows matching the filter modal, null when no filter was applied
        filterMatches: null,
        apiUrl: import.meta.env.VITE_API_URL,
        showFilterModal: false,
        downloadIcon,
        filterIcon,
        sort: { key: null, direction: 'asc' },
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
          link: `/admin/timesheets/${this.$route.params.timesheet_id}/periods`,
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
      },
      // Both the role tab and the filter modal apply, changing one keeps the other
      filteredItems() {
        if (this.filterMatches === null) {
          return this.roleFilteredItems
        }

        const matches = new Set(this.filterMatches)

        return this.roleFilteredItems.filter(item => matches.has(item))
      },
      sortedItems() {
        const key = this.sort.key
        if (!key) {
          return this.filteredItems
        }

        let type = 'string'
        if (NUMERIC_SORT_KEYS.has(key)) {
          type = 'number'
        } else if (key === 'last_entry_date') {
          type = 'date'
        } else if (key.startsWith('custom_field_')) {
          const field = this.customFields.find((item) => `custom_field_${item.id}` === key)
          if (field?.input_type === 'number') {
            type = 'number'
          }
        }

        return sortRows(this.filteredItems, {
          key,
          direction: this.sort.direction,
          type,
          getValue: key === 'identifier' ? getUserIdentifier : undefined,
        })
      },
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      sortBy(key) {
        this.sort = nextSortState(this.sort, key)
      },
      ariaSortFor(key) {
        return ariaSort(this.sort, key)
      },
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
        this.roleFilteredItems = users
      },
      getCsv() {
        if (this.filteredItems.length === 0) {
          this.awn?.warning('No records to export.')
          return
        }

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
      openFilterModal() {
        this.showFilterModal = true
      },
      applyFilters(filteredData) {
        this.filterMatches = filteredData
      }
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
