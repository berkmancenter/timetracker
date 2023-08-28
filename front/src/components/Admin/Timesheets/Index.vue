<template>
  <div class="content admin-timesheets">
    <h1 class="is-size-1">Timesheets</h1>

    <p>Create new timesheets for yourself, ensuring a seamless record of your activities. You can send invitations to other users, facilitating collaborative participation.</p>

    <form class="form">
      <div class="mb-4">
        <router-link :to="'/admin/timesheets/new'" class="button is-success">Add timesheet</router-link>
      </div>

      <admin-table :tableClasses="['admin-timesheets-table']">
        <thead>
          <tr class="no-select">
            <th>Name</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="timesheet in $store.state.admin.timesheets" :key="timesheet.id">
            <td>{{ timesheet.name }}</td>
            <td>
              <router-link :to="`/admin/timesheets/${timesheet.id}/edit`">
                <Icon :src="editIcon" />
              </router-link>
              <a title="Delete this timesheet" @click.prevent="deleteTimesheet(timesheet)">
                <Icon :src="minusIcon" />
              </a>
            </td>
          </tr>
          <tr v-if="$store.state.admin.timesheets.length === 0">
            <td colspan="7">No timesheets found.</td>
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
    name: 'AdminTimesheets',
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
        this.loadTimesheets()
      },
      async loadTimesheets() {
        this.mitt.emit('spinnerStart')

        const timesheets = await this.$store.dispatch('admin/fetchTimesheets')

        this.$store.dispatch('admin/setTimesheets', timesheets)

        this.mitt.emit('spinnerStop')
      },
      deleteTimesheet(timesheet) {
        const that = this

        Swal.fire({
          title: 'Removing timesheet',
          text: `Are you sure to remove ${timesheet.name}?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/deleteTimesheets', [timesheet.id])

            if (response.ok) {
              this.awn.success('Timesheet has been removed.')
              that.loadTimesheets()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
      },
      async cloneTimesheet(timesheet) {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/cloneTimesheet', timesheet.id)

        if (response.ok) {
          this.awn.success(`Timesheet "${timesheet.name}" has been cloned.`)
          this.loadTimesheets()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
    },
  }
</script>
