<template>
  <div class="content admin-users">
    <h1 class="is-size-1">Users</h1>

    <form class="form">
      <div class="mb-4">
        <a class="button is-danger mr-2" @click="deleteUsers()">Remove selected</a>
        <a class="button is-info mr-2" @click="toggleAdminUsers()">Toggle admin selected</a>
        <a class="button is-info" @click="sudo()">View other users timesheets</a>
      </div>

      <super-admin-filter :users="$store.state.admin.users" @change="superAdminFilterChanged" />

      <admin-table :tableClasses="['admin-users-table']">
        <thead>
          <tr class="no-select">
            <th data-sort-method="none" class="no-sort">
              <input type="checkbox" ref="toggleAllCheckbox" @click="toggleAll()">
            </th>
            <th>Username</th>
            <th>Email</th>
            <th>Admin</th>
            <th>Created</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in filteredItems" :key="user.id">
            <td>
              <input type="checkbox" v-model="user.selected">
            </td>
            <td>{{ cleanUsername(user.username) }}</td>
            <td>{{ user.email }}</td>
            <td>
              <span class="is-hidden">{{ user.superadmin }}</span>
              <Icon :src="iconBool(user.superadmin)" :interactive="false" />
            </td>
            <td>{{ user.created_at }}</td>
            <td>
              <a title="Delete this user" @click.prevent="deleteUser(user)">
                <Icon :src="minusIcon" />
              </a>
            </td>
          </tr>
        </tbody>
      </admin-table>
    </form>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import yesIcon from '@/images/yes.svg'
  import noIcon from '@/images/no.svg'
  import Swal from 'sweetalert2'
  import cleanUsername from '@/lib/clean-username'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'

  export default {
    name: 'AdminUsers',
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
        cleanUsername,
        filteredItems: [],
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

        const users = await this.$store.dispatch('admin/fetchUsers')

        this.$store.dispatch('admin/setUsers', users)

        this.mitt.emit('spinnerStop')
      },
      iconBool(isAdmin) {
        if (isAdmin) {
          return this.yesIcon
        } else {
          return this.noIcon
        }
      },
      deleteUser(user) {
        const that = this

        Swal.fire({
          title: 'Removing user',
          text: `Are you sure to remove ${user.email}?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/deleteUsers', [user.id])

            if (response.ok) {
              this.awn.success('User has been removed.')
              that.loadUsers()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
      },
      deleteUsers() {
        const that = this
        const usersIds = this.filteredItems
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        Swal.fire({
          title: 'Removing users',
          text: `Are you sure to remove selected users?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/deleteUsers', usersIds)

            if (response.ok) {
              this.awn.success('Selected users have been removed.')
              that.loadUsers()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
      },
      async toggleAdminUsers() {
        const usersIds = this.filteredItems
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/toggleAdminUsers', usersIds)

        if (response.ok) {
          this.awn.success('Selected users have been modified.')
          this.loadUsers()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
      async sudo() {
        const usersIds = this.filteredItems
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/sudo', usersIds)

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

        this.$store.state.admin.users
          .map((user) => {
            user.selected = newStatus

            return user
          })
      },
      superAdminFilterChanged(users) {
        this.filteredItems = users
      },
    },
  }
</script>

<style lang="scss"></style>
