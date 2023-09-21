<template>
  <div class="content admin-periods">
    <h4 class="is-size-4">Periods</h4>

    <p>Periods offer a comprehensive way to access statistical data regarding timesheet usage by users within a specified timeframe.</p>

    <form class="form">
      <div class="mb-4">
        <router-link :to="'/admin/periods/new'" class="button is-success">Add period</router-link>
      </div>

      <admin-table :tableClasses="['admin-periods-table']">
        <thead>
          <tr class="no-select">
            <th>Name</th>
            <th>Timesheet</th>
            <th>From</th>
            <th>To</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="period in $store.state.admin.periods" :key="period.id">
            <td>{{ period.name }}</td>
            <td>{{ period.timesheet.name }}</td>
            <td class="no-break">{{ period.from }}</td>
            <td class="no-break">{{ period.to }}</td>
            <td class="admin-table-actions">
              <div class="admin-table-actions">
                <router-link title="Edit period" :to="`/admin/periods/${period.id}/edit`">
                  <Icon :src="editIcon" />
                </router-link>
                <a title="Clone period" @click.prevent="clonePeriod(period)">
                  <Icon :src="cloneIcon" />
                </a>
                <a title="Delete period" @click.prevent="deletePeriod(period)">
                  <Icon :src="minusIcon" />
                </a>
                <router-link title="Set period hours" :to="`/admin/periods/${period.id}/credits`">
                  <Icon :src="hoursIcon" />
                </router-link>
                <router-link title="Period statistics" :to="`/admin/periods/${period.id}/stats`">
                  <Icon :src="statsIcon" />
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
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import statsIcon from '@/images/stats.svg'
  import hoursIcon from '@/images/hours.svg'
  import editIcon from '@/images/edit.svg'
  import cloneIcon from '@/images/clone.svg'
  import Swal from 'sweetalert2'
  import AdminTable from '@/components/Admin/AdminTable.vue'

  export default {
    name: 'AdminPeriods',
    components: {
      Icon,
      AdminTable,
    },
    data() {
      return {
        minusIcon,
        statsIcon,
        hoursIcon,
        editIcon,
        cloneIcon,
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      initialDataLoad() {
        this.loadPeriods()
      },
      async loadPeriods() {
        this.mitt.emit('spinnerStart')

        const periods = await this.$store.dispatch('admin/fetchPeriods')

        this.$store.dispatch('admin/setPeriods', periods)

        this.mitt.emit('spinnerStop')
      },
      deletePeriod(period) {
        const that = this

        Swal.fire({
          title: 'Removing period',
          text: `Are you sure to remove ${period.name}?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/deletePeriods', [period.id])

            if (response.ok) {
              this.awn.success('Period has been removed.')
              that.loadPeriods()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
      },
      async clonePeriod(period) {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/clonePeriod', period.id)

        if (response.ok) {
          this.awn.success(`Period "${period.name}" has been cloned.`)
          this.loadPeriods()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
    },
  }
</script>
