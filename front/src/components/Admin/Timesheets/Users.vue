<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

  <div class="content admin-timesheet-users">
    <h4 class="is-size-4">Users</h4>

    <p>Manage users for <span class="tag is-black is-medium">{{ timesheet.name }}</span> timesheet.</p>

    <form class="form">
      <div class="mb-4">
        <ActionButton
          :icon="listIcon"
          buttonText="View selected users timesheets"
          @click="sudoUsers()"
        />
      </div>

      <super-admin-filter :users="users" @change="superAdminFilterChanged" />

      <admin-table :tableClasses="['admin-timesheet-users-table']">
        <thead>
          <tr class="no-select">
            <th data-sort-method="none" class="no-sort">
              <input type="checkbox" ref="toggleAllCheckbox" @click="toggleAll()">
            </th>
            <th>Email</th>
            <th>Joined</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in filteredItems" :key="user.id">
            <td class="admin-table-selector">
              <input type="checkbox" v-model="user.selected">
            </td>
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
            <td colspan="4">No users found.</td>
          </tr>
        </tbody>
      </admin-table>
    </form>
  </div>

  <div ref="adminTimesheetUsersSetRoleTemplate" class="is-hidden">
      <div class="content admin-timesheet-users-set-role">
        <div class="is-size-5 mb-4">Choose role to set</div>

        <div class="field">
          <div class="control" v-for="(option, index) in roles" :key="index">
            <label class="radio">
              <input
                type="radio"
                name="adminTimesheetUsersSetRole"
                :value="option"
                class="mb-2"
              >
              {{ option }}
            </label>
          </div>
        </div>
      </div>
    </div>

  <Modal
    v-model="removeUserFromTimesheetModalStatus"
    title="Remove user from timesheet"
    @confirm="removeUserFromTimesheet()"
    @cancel="removeUserFromTimesheetModalStatus = false"
  >
    <p>Are you sure you remove <span class="has-text-weight-bold">{{ removeUserFromTimesheetCurrent.email }}</span> from the timesheet?</p>
    <div class="notification is-danger is-light mt-2">They won't be able to use it any more.</div>
  </Modal>

  <Modal
    v-model="changeUsersRoleModalStatus"
    title="Change user role"
    @confirm="changeUsersRole()"
    @cancel="changeUsersRoleModalStatus = false"
  >
    <p>Changing the user role for <span class="has-text-weight-bold">{{ changeUsersRoleCurrent.email }}</span>.</p>
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
  import yesIcon from '@/images/yes.svg'
  import noIcon from '@/images/no.svg'
  import listIcon from '@/images/list_main.svg'
  import toggleAdminIcon from '@/images/toggle_admin.svg'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'
  import Modal from '@/components/Shared/Modal.vue'
  import ActionButton from '@/components/Shared/ActionButton.vue'
  import { formatIsoDateTimeToLocaleString } from '@/lib/date-time.js'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'

  export default {
    name: 'AdminTimesheetUsers',
    components: {
      Icon,
      AdminTable,
      SuperAdminFilter,
      Modal,
      ActionButton,
      Breadcrumbs,
    },
    data() {
      return {
        minusIcon,
        yesIcon,
        noIcon,
        listIcon,
        toggleAdminIcon,
        users: [],
        filteredItems: [],
        timesheetId: this.$route.params.id,
        roles: [
          'admin',
          'user',
        ],
        setRoleSelectedRole: 'user',
        removeUserFromTimesheetModalStatus: false,
        removeUserFromTimesheetCurrent: null,
        changeUsersRoleModalStatus: false,
        changeUsersRoleCurrent: null,
        changeUsersRoleSelected: 'admin',
        formatIsoDateTimeToLocaleString,
        timesheet: {},
      }
    },
    computed: {
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
      async initialDataLoad() {
        this.mitt.emit('spinnerStart')

        this.users = await this.$store.dispatch('admin/fetchTimesheetUsers', this.timesheetId)
        this.timesheet = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.id)

        this.mitt.emit('spinnerStop')
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
      async sudoUsers() {
        const usersIds = this.filteredItems
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/sudoUsersTimesheet', {
          users: usersIds,
          timesheetId: this.timesheetId,
        })

        if (response.ok) {
          const user = await this.$store.dispatch('shared/fetchUser')

          this.$store.dispatch('shared/setUser', user)
          this.awn.success('You can now see timesheets of selected users.')

          this.$router.push(
            {
              name: 'tracker.index',
              params: {
                timesheet: this.timesheet.uuid,
                month: null,
              }
            }
          )
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
      toggleAll() {
        const newStatus = this.$refs.toggleAllCheckbox.checked

        this.users
          .map((user) => {
            user.selected = newStatus

            return user
          })
      },
      changeUsersRoleModalOpen(user) {
        this.changeUsersRoleCurrent = user
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
