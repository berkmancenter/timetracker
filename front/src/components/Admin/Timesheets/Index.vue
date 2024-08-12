<template>
  <div class="content admin-timesheets">
    <h4 class="is-size-4">Timesheets</h4>

    <p>Create new timesheets for yourself, ensuring a seamless record of your activities. You can send invitations to other users, facilitating collaborative participation.</p>

    <form class="form">
      <div class="mb-4">
        <router-link :to="'/admin/timesheets/new'" class="button is-success">
          <Icon :src="addIcon" :interactive="false" />
          Add timesheet
        </router-link>
      </div>

      <admin-table :tableClasses="['admin-timesheets-table']">
        <thead>
          <tr class="no-select">
            <th>Name</th>
            <th>Created</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="timesheet in orderedTimesheets" :key="timesheet.id">
            <td>{{ timesheet.name }}</td>
            <td>{{ formatIsoDateTimeToLocaleString(timesheet.created_at) }}</td>
            <td class="admin-table-actions">
              <div class="admin-table-actions">
                <router-link title="Edit timesheet" :to="`/admin/timesheets/${timesheet.id}/edit`" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="editIcon" />
                </router-link>
                <router-link title="Invite users to timesheet" :to="`/admin/timesheets/${timesheet.id}/invite`" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="inviteIcon" />
                </router-link>
                <router-link title="List of timesheet users" :to="`/admin/timesheets/${timesheet.id}/users`" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="usersIcon" />
                </router-link>
                <a title="Delete timesheet" @click.prevent="removeTimesheetConfirm(timesheet)" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="minusIcon" />
                </a>
                <a title="Leave timesheet" @click.prevent="leaveTimesheetConfirm(timesheet)">
                  <Icon :src="leaveIcon" />
                </a>
              </div>
            </td>
          </tr>
          <tr v-if="$store.state.admin.timesheets.length === 0">
            <td colspan="2">No timesheets found.</td>
          </tr>
        </tbody>
      </admin-table>
    </form>
  </div>

  <Modal
    v-model="removeTimesheetModalStatus"
    title="Remove user from timesheet"
    @confirm="removeTimesheet()"
    @cancel="removeTimesheetModalStatus = false"
  >
    <p>Are you sure you remove the <span class="has-text-weight-bold">{{ removeTimesheetModalCurrent.name }}</span> timesheet?</p>
    <div class="notification is-danger is-light mt-2">This will remove all the existing time entries reported in the timesheet.</div>
  </Modal>

  <Modal
    v-model="leaveTimesheetModalStatus"
    title="Leave timesheet"
    @confirm="leaveTimesheet()"
    @cancel="leaveTimesheetModalStatus = false"
  >
    <p>Are you sure to leave <span class="has-text-weight-bold">{{ leaveTimesheetModalCurrent.name }}</span>?</p>
    <div class="notification is-danger is-light mt-2">After leaving the timesheet you won't be able to use it any more.</div>
  </Modal>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import statsIcon from '@/images/stats.svg'
  import hoursIcon from '@/images/hours.svg'
  import editIcon from '@/images/edit.svg'
  import cloneIcon from '@/images/clone.svg'
  import inviteIcon from '@/images/invite.svg'
  import leaveIcon from '@/images/leave.svg'
  import usersIcon from '@/images/users.svg'
  import addIcon from '@/images/add_white.svg'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import orderBy from 'lodash/orderBy'
  import Modal from '@/components/Shared/Modal.vue'
  import { formatIsoDateTimeToLocaleString } from '@/lib/date-time.js'

  export default {
    name: 'AdminTimesheets',
    components: {
      Icon,
      AdminTable,
      Modal,
    },
    data() {
      return {
        minusIcon,
        statsIcon,
        hoursIcon,
        editIcon,
        cloneIcon,
        inviteIcon,
        leaveIcon,
        usersIcon,
        addIcon,
        removeTimesheetModalStatus: false,
        removeTimesheetModalCurrent: null,
        leaveTimesheetModalStatus: false,
        leaveTimesheetModalCurrent: null,
        formatIsoDateTimeToLocaleString,
      }
    },
    created() {
      this.initialDataLoad()
    },
    computed: {
      orderedTimesheets() {
        return orderBy(this.$store.state.admin.timesheets, 'name')
      }
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
      removeTimesheetConfirm(timesheet) {
        this.removeTimesheetModalCurrent = timesheet
        this.removeTimesheetModalStatus = true
      },
      async removeTimesheet() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/deleteTimesheets', [this.removeTimesheetModalCurrent.id])

        if (response.ok) {
          this.awn.success('Timesheet has been removed.')
          this.loadTimesheets()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')

        this.removeTimesheetModalStatus = false
      },
      leaveTimesheetConfirm(timesheet) {
        this.leaveTimesheetModalCurrent = timesheet
        this.leaveTimesheetModalStatus = true
      },
      async leaveTimesheet(timesheet) {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/leaveTimesheet', this.leaveTimesheetModalCurrent)

        if (response.ok) {
          this.awn.success('You have left the timesheet successfully.')
          this.loadTimesheets()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')

        this.leaveTimesheetModalStatus = false
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
      adminInTimesheet(timesheet) {
        return timesheet.roles.includes('admin')
      },
    },
  }
</script>
