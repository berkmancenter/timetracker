<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

  <div class="content admin-periods">
    <h4 class="is-size-4">Periods</h4>

    <p>Periods offer a comprehensive way to access statistical data regarding timesheet usage by users within a specified timeframe.</p>

    <form class="form">
      <div class="mb-4">
        <router-link :to="`/admin/timesheets/${this.$store.state.admin.timesheet.id}/periods/new`">
          <ActionButton
            class="is-success"
            :icon="addIcon"
            buttonText="Add period"
            :button="true"
          />
        </router-link>

      </div>

      <admin-table :tableClasses="['admin-periods-table']">
        <thead>
          <tr class="no-select">
            <th>Name</th>
            <th>From</th>
            <th>To</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="period in orderedPeriods"
            :key="period.id"
            class="admin-periods-table-row"
            @click.middle="goToPeriodStats(period.id, $event)"
            @click="goToPeriodStats(period.id, $event)"
            title="Click to view period stats"
          >
            <td>{{ period.name }}</td>
            <td class="no-break">{{ period.from }}</td>
            <td class="no-break">{{ period.to }}</td>
            <td class="admin-table-actions">
              <div>
                <router-link title="Edit period" :to="`/admin/timesheets/${this.$route.params.timesheet_id}/periods/${period.id}/edit`">
                  <Icon :src="editIcon" />
                </router-link>
                <a title="Clone period" @click.prevent="clonePeriod(period)">
                  <Icon :src="cloneIcon" />
                </a>
                <a title="Delete period" @click.prevent="deletePeriodConfirm(period)">
                  <Icon :src="minusIcon" />
                </a>
                <router-link title="Set period hours" :to="`/admin/timesheets/${this.$route.params.timesheet_id}/periods/${period.id}/credits`">
                  <Icon :src="hoursIcon" />
                </router-link>
              </div>
            </td>
          </tr>
          <tr v-if="$store.state.admin.periods.length === 0">
            <td colspan="7">No periods found.</td>
          </tr>
        </tbody>
      </admin-table>
    </form>
  </div>

  <Modal
    v-model="deletePeriodModalStatus"
    title="Remove period"
    @confirm="deletePeriod()"
    @cancel="deletePeriodModalStatus = false"
  >
    Are you sure you remove the period?
  </Modal>
</template>

<script>
  import minusIcon from '@/images/minus.svg'
  import statsIcon from '@/images/stats.svg'
  import hoursIcon from '@/images/hours.svg'
  import editIcon from '@/images/edit.svg'
  import cloneIcon from '@/images/clone.svg'
  import addIcon from '@/images/add_white.svg'

  import AdminTable from '@/components/Admin/AdminTable.vue'
  import Modal from '@/components/Shared/Modal.vue'
  import ActionButton from '@/components/Shared/ActionButton.vue'
  import Icon from '@/components/Shared/Icon.vue'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'

  import orderBy from 'lodash/orderBy'

  export default {
    name: 'AdminPeriods',
    components: {
      Icon,
      AdminTable,
      Modal,
      ActionButton,
      Breadcrumbs,
    },
    data() {
      return {
        minusIcon,
        statsIcon,
        hoursIcon,
        editIcon,
        cloneIcon,
        addIcon,

        deletePeriodModalStatus: false,
        deletePeriodCurrent: null,
      }
    },
    created() {
      this.initialDataLoad()
    },
    computed: {
      orderedPeriods() {
        return orderBy(this.$store.state.admin.periods, 'name')
      },
      breadcrumbs() {
        let breadcrumbs = []

        breadcrumbs.push({
          text: 'Timesheets',
          link: '/admin/timesheets',
        })

        breadcrumbs.push({
          text: this.$store.state.admin.timesheet.name,
        })

        breadcrumbs.push({
          text: 'Periods',
        })

        return breadcrumbs
      },
    },
    methods: {
      async initialDataLoad() {
        this.mitt.emit('spinnerStart')

        const periods = await this.$store.dispatch('admin/fetchPeriods', this.$route.params.timesheet_id)
        const timesheet = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.timesheet_id)

        this.$store.dispatch('admin/setPeriods', periods)
        this.$store.dispatch('admin/setTimesheet', timesheet)

        this.mitt.emit('spinnerStop')
      },
      deletePeriodConfirm(period) {
        this.deletePeriodModalStatus = true
        this.deletePeriodCurrent = period
      },
      async deletePeriod() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/deletePeriods', {
          periods: [this.deletePeriodCurrent.id],
          timesheetId: this.$store.state.admin.timesheet.id,
        })

        if (response.ok) {
          this.awn.success('Period has been removed.')
          this.initialDataLoad()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')

        this.deletePeriodModalStatus = false
      },
      async clonePeriod(period) {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/clonePeriod', {
          periodId: period.id,
          timesheetId: this.$store.state.admin.timesheet.id,
        })

        if (response.ok) {
          this.awn.success(`Period "${period.name}" has been cloned.`)
          this.initialDataLoad()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
      goToPeriodStats(id, event) {
        if (event.target.closest('.admin-table-actions')) {
          return
        }

        const url = `/admin/timesheets/${this.$route.params.timesheet_id}/periods/${id}/stats`

        if (event.button === 1) {
          // Middle click: open in new tab
          window.open(url, '_blank')
        } else if (event.button === 0) {
          // Left click: navigate in current tab
          this.$router.push(url)
        }
      },
    },
  }
</script>

<style lang="scss">
  .admin-periods {
    &-table {
      &-row {
        cursor: pointer;
      }
    }
  }

  .admin-table-actions {
    cursor: default;
  }
</style>
