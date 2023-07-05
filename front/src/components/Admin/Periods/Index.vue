<template>
  <div class="content admin-periods">
    <h1 class="is-size-1">Periods</h1>

    <form class="form">
      <div class="mb-4">
        <router-link :to="'/admin/periods/new'" class="button is-success">Add period</router-link>
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
          <tr v-for="period in $store.state.admin.periods" :key="period.id">
            <td>{{ period.name }}</td>
            <td>{{ period.from }}</td>
            <td>{{ period.to }}</td>
            <td>
              <router-link :to="`/admin/periods/${period.id}/edit`">
                <Icon :src="editIcon" />
              </router-link>
              <a title="Clone this period" @click.prevent="clonePeriod(period)">
                <Icon :src="cloneIcon" />
              </a>
              <a title="Delete this period" @click.prevent="deletePeriod(period)">
                <Icon :src="minusIcon" />
              </a>
              <router-link title="Set period credits" :to="`/admin/periods/${period.id}/credits`">
                <Icon :src="creditsIcon" />
              </router-link>
              <router-link title="Period statistics" :to="`/admin/periods/${period.id}/stats`">
                <Icon :src="statsIcon" />
              </router-link>
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
  import creditsIcon from '@/images/credits.svg'
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
        creditsIcon,
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
