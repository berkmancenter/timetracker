<template>
  <div class="content admin-timesheet-users">
    <h4 class="is-size-4">Users</h4>

    <form class="form">
      <div class="mb-4">
        <a class="button is-info" @click="sudoUsers()">View selected users timesheets</a>
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
            <td class="no-break">{{ user.joined }}</td>
            <td class="admin-table-actions">
              <div class="admin-table-actions">
                <a title="Remove user from timesheet" @click.prevent="removeFromTimesheet(user)">
                  <Icon :src="minusIcon" />
                </a>
                <a title="Change role" @click.prevent="changeUsersRole(user)">
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
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import yesIcon from '@/images/yes.svg'
  import noIcon from '@/images/no.svg'
  import toggleAdminIcon from '@/images/toggle_admin.svg'
  import Swal from 'sweetalert2'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'

  export default {
    name: 'AdminTimesheetUsers',
    components: {
      Icon,
      AdminTable,
      SuperAdminFilter,
    },
    data() {
      return {
        minusIcon,
        yesIcon,
        noIcon,
        toggleAdminIcon,
        users: [],
        filteredItems: [],
        timesheetId: this.$route.params.id,
        roles: [
          'admin',
          'user',
        ],
        setRoleSelectedRole: 'user',
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      initialDataLoad() {
        this.loadUsers()
      },
      async loadUsers() {
        this.mitt.emit('spinnerStart')

        const users = await this.$store.dispatch('admin/fetchTimesheetUsers', this.timesheetId)

        this.users = users

        this.mitt.emit('spinnerStop')
      },
      removeFromTimesheet(user) {
        const that = this

        Swal.fire({
          title: 'Removing user',
          html: `Are you sure to remove ${user.email} from this timesheet?<br><strong>They won't be able to use it any more.</strong>`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/deleteUsersFromTimesheet', {
              users: [user.id],
              timesheetId: this.timesheetId,
            })

            if (response.ok) {
              this.awn.success('Users have been removed.')
              that.loadUsers()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
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
      changeUsersRole(user) {
        const templateElementSelector = '.swal2-html-container .admin-timesheet-users-set-role'

        Swal.fire({
          icon: null,
          showCancelButton: true,
          confirmButtonText: 'Set',
          confirmButtonColor: this.colors.main,
          html: this.$refs.adminTimesheetUsersSetRoleTemplate.innerHTML,
          didOpen: () => {
            document.querySelector(templateElementSelector).querySelector('input').checked = true
          },
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/changeTimesheetUsersRole', {
              users: [user.id],
              timesheetId: this.timesheetId,
              role: document.querySelector(templateElementSelector).querySelector('input:checked').value,
            })

            if (response.ok) {
              this.awn.success('User role have been updated.')
              this.loadUsers()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
      },
      superAdminFilterChanged(users) {
        this.filteredItems = users
      },
    },
  }
</script>

<style lang="scss"></style>
