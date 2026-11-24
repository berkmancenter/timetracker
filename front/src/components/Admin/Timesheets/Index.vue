<template>
  <div class="content admin-timesheets">
    <h4 class="is-size-4">Timesheets</h4>

    <p>Create new timesheets for yourself, ensuring a seamless record of your activities. You can send invitations to other users, facilitating collaborative participation.</p>

    <form class="form">
      <div class="mb-4">
        <router-link :to="'/admin/timesheets/new'">
          <ActionButton
            class="is-success"
            :icon="addIcon"
            buttonText="Add timesheet"
            :button="true"
          />
        </router-link>
      </div>

      <AdminTable :tableClasses="['admin-timesheets-table']">
        <thead>
          <tr class="no-select">
            <th class="admin-table-sortable" :aria-sort="ariaSortFor('name')" @click="sortBy('name')">Name</th>
            <th class="admin-table-sortable" :aria-sort="ariaSortFor('created_at')" @click="sortBy('created_at')">Created</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="timesheet in orderedTimesheets" :key="timesheet.id">
            <td>{{ timesheet.name }}</td>
            <td>{{ formatIsoDateTimeToLocaleString(timesheet.created_at) }}</td>
            <td class="admin-table-actions">
              <div>
                <router-link title="Edit timesheet" :to="`/admin/timesheets/${timesheet.id}/edit`" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="editIcon" />
                </router-link>
                <router-link title="Invite users to timesheet" :to="`/admin/timesheets/${timesheet.id}/invite`" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="inviteIcon" />
                </router-link>
                <router-link title="Periods" :to="`/admin/timesheets/${timesheet.id}/periods`" v-if="adminInTimesheet(timesheet)">
                  <Icon :src="periodIcon" />
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
            <td colspan="3">No timesheets found.</td>
          </tr>
        </tbody>
      </AdminTable>
    </form>
  </div>

  <Modal
    v-model="removeTimesheetModalStatus"
    title="Remove timesheet"
    @confirm="removeTimesheet()"
    @cancel="removeTimesheetModalStatus = false"
  >
    <p>Are you sure you remove the <span class="has-text-weight-bold">{{ removeTimesheetModalCurrent?.name }}</span> timesheet?</p>
    <div class="notification is-danger is-light mt-2">This will remove all the existing time entries reported in the timesheet.</div>
  </Modal>

  <Modal
    v-model="leaveTimesheetModalStatus"
    title="Leave timesheet"
    @confirm="leaveTimesheet()"
    @cancel="leaveTimesheetModalStatus = false"
  >
    <p>Are you sure to leave <span class="has-text-weight-bold">{{ leaveTimesheetModalCurrent?.name }}</span>?</p>
    <div class="notification is-danger is-light mt-2">After leaving the timesheet you won't be able to use it any more.</div>
  </Modal>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import editIcon from '@/images/edit.svg'
  import inviteIcon from '@/images/invite.svg'
  import leaveIcon from '@/images/leave.svg'
  import usersIcon from '@/images/users.svg'
  import addIcon from '@/images/add_white.svg'
  import periodIcon from '@/images/period.svg'

  import { formatIsoDateTimeToLocaleString } from '@/lib/date-time.js'
  import { ariaSort, nextSortState, sortRows } from '@/lib/table-sort.js'

  import ActionButton from '@/components/Shared/ActionButton.vue'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import Modal from '@/components/Shared/Modal.vue'

  export default {
    name: 'AdminTimesheets',
    components: {
      Icon,
      AdminTable,
      Modal,
      ActionButton,
    },
    data() {
      return {
        minusIcon,
        editIcon,
        inviteIcon,
        leaveIcon,
        usersIcon,
        addIcon,
        periodIcon,

        removeTimesheetModalStatus: false,
        removeTimesheetModalCurrent: null,
        leaveTimesheetModalStatus: false,
        leaveTimesheetModalCurrent: null,
        sort: { key: 'name', direction: 'asc' },
        formatIsoDateTimeToLocaleString,
      }
    },
    created() {
      this.initialDataLoad()
    },
    computed: {
      orderedTimesheets() {
        const type = this.sort.key === 'created_at' ? 'date' : 'string'
        return sortRows(this.$store.state.admin.timesheets, {
          key: this.sort.key,
          direction: this.sort.direction,
          type,
        })
      },
    },
    methods: {
      sortBy(key) {
        this.sort = nextSortState(this.sort, key)
      },
      ariaSortFor(key) {
        return ariaSort(this.sort, key)
      },
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
      async leaveTimesheet() {
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
      adminInTimesheet(timesheet) {
        return timesheet.roles.includes('admin')
      },
    },
  }
</script>
