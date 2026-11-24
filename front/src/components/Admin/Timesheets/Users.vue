<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

  <div class="content admin-timesheet-users">
    <h4 class="is-size-4">Users</h4>

    <p>Manage users for <span class="tag is-black is-medium">{{ timesheet.name }}</span> timesheet.</p>

    <form class="form">
      <SuperAdminFilter :users="users" @change="superAdminFilterChanged" />

      <AdminTable :tableClasses="['admin-timesheet-users-table']">
        <thead>
          <tr class="no-select">
            <th class="admin-table-sortable" :aria-sort="ariaSortFor('email')" @click="sortBy('email')">Email</th>
            <th class="admin-table-sortable" :aria-sort="ariaSortFor('joined')" @click="sortBy('joined')">Joined</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in sortedItems" :key="user.id">
            <td>{{ user.email }}</td>
            <td class="no-break">{{ formatIsoDateTimeToLocaleString(user.joined) }}</td>
            <td class="admin-table-actions">
              <div>
                <a title="Remove user from timesheet" @click.prevent="removeFromTimesheetConfirm(user)">
                  <Icon :src="minusIcon" />
                </a>
                <a title="Change role" @click.prevent="changeUsersRoleModalOpen(user)">
                  <Icon :src="toggleAdminIcon" />
                </a>
              </div>
            </td>
          </tr>
          <tr v-if="filteredItems.length === 0">
            <td colspan="3">No users found.</td>
          </tr>
        </tbody>
      </AdminTable>
    </form>
  </div>

  <Modal
    v-model="removeUserFromTimesheetModalStatus"
    title="Remove user from timesheet"
    @confirm="removeUserFromTimesheet()"
    @cancel="removeUserFromTimesheetModalStatus = false"
  >
    <p>Are you sure you remove <span class="has-text-weight-bold">{{ removeUserFromTimesheetCurrent?.email }}</span> from the timesheet?</p>
    <div class="notification is-danger is-light mt-2">They won't be able to use it any more.</div>
  </Modal>

  <Modal
    v-model="changeUsersRoleModalStatus"
    title="Change user role"
    @confirm="changeUsersRole()"
    @cancel="changeUsersRoleModalStatus = false"
  >
    <p>Changing the user role for <span class="has-text-weight-bold">{{ changeUsersRoleCurrent?.email }}</span>.</p>
    <p class="mt-2">Choose role to set:</p>

    <div class="field">
      <div class="control" v-for="(option, index) in roles" :key="index">
        <label class="radio">
          <input
            type="radio"
            name="adminTimesheetUsersSetRole"
            v-model="changeUsersRoleSelected"
            :value="option"
            class="mb-2"
          >
          {{ option }}
        </label>
      </div>
    </div>
  </Modal>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import toggleAdminIcon from '@/images/toggle_admin.svg'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'
  import Modal from '@/components/Shared/Modal.vue'
  import { formatIsoDateTimeToLocaleString } from '@/lib/date-time.js'
  import { ariaSort, nextSortState, sortRows } from '@/lib/table-sort.js'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'

  export default {
    name: 'AdminTimesheetUsers',
    components: {
      Icon,
      AdminTable,
      SuperAdminFilter,
      Modal,
      Breadcrumbs,
    },
    data() {
      return {
        minusIcon,
        toggleAdminIcon,
        users: [],
        filteredItems: [],
        timesheetId: this.$route.params.id,
        roles: [
          'admin',
          'user',
        ],
        removeUserFromTimesheetModalStatus: false,
        removeUserFromTimesheetCurrent: null,
        changeUsersRoleModalStatus: false,
        changeUsersRoleCurrent: null,
        changeUsersRoleSelected: 'admin',
        sort: { key: null, direction: 'asc' },
        formatIsoDateTimeToLocaleString,
        timesheet: {},
      }
    },
    computed: {
      sortedItems() {
        const type = this.sort.key === 'joined' ? 'date' : 'string'
        return sortRows(this.filteredItems, {
          key: this.sort.key,
          direction: this.sort.direction,
          type,
        })
      },
      breadcrumbs() {
        return [
          {
            text: 'Timesheets',
            link: '/admin/timesheets',
          },
          {
            text: this.timesheet.name,
          },
          {
            text: 'Users',
          },
        ]
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
      async initialDataLoad() {
        this.mitt.emit('spinnerStart')

        await this.loadUsers()
        this.timesheet = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.id)

        this.mitt.emit('spinnerStop')
      },
      async loadUsers() {
        this.users = await this.$store.dispatch('admin/fetchTimesheetUsers', this.timesheetId)
        this.filteredItems = this.users
      },
      removeFromTimesheetConfirm(user) {
        this.removeUserFromTimesheetCurrent = user
        this.removeUserFromTimesheetModalStatus = true
      },
      async removeUserFromTimesheet() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/deleteUsersFromTimesheet', {
          users: [this.removeUserFromTimesheetCurrent.id],
          timesheetId: this.timesheetId,
        })

        if (response.ok) {
          this.awn.success('Users have been removed.')
          this.loadUsers()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')

        this.removeUserFromTimesheetModalStatus = false
      },
      changeUsersRoleModalOpen(user) {
        this.changeUsersRoleCurrent = user
        this.changeUsersRoleSelected = user.roles?.includes('admin') ? 'admin' : 'user'
        this.changeUsersRoleModalStatus = true
      },
      async changeUsersRole() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/changeTimesheetUsersRole', {
          users: [this.changeUsersRoleCurrent.id],
          timesheetId: this.timesheetId,
          role: this.changeUsersRoleSelected,
        })

        if (response.ok) {
          this.awn.success('User role have been updated.')
          this.loadUsers()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')

        this.changeUsersRoleModalStatus = false
      },
      superAdminFilterChanged(users) {
        this.filteredItems = users
      },
    },
  }
</script>

<style lang="scss"></style>
