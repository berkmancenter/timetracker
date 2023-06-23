<template>
  <div class="content admin-users">
    <h1 class="is-size-1">Users</h1>

    <form class="form">
      <div class="mb-4">
        <a class="button is-danger mr-2" @click="deleteUsers()">Remove selected</a>
        <a class="button is-info mr-2" @click="toggleAdminUsers()">Toggle admin selected</a>
        <a class="button is-info" @click="sudo()">View other users timesheets</a>
      </div>

      <table class="table table-hovered admin-users-table" ref="usersTable">
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
          <tr v-for="user in $store.state.admin.users" :key="user.id">
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
      </table>
    </form>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import minusIcon from '@/images/minus.svg'
  import yesIcon from '@/images/yes.svg'
  import noIcon from '@/images/no.svg'
  import Swal from 'sweetalert2'
  import 'tablesort/tablesort.css'
  import Tablesort from 'tablesort'

  export default {
    name: 'AdminUsers',
    components: {
      Icon,
    },
    data() {
      return {
        minusIcon,
        yesIcon,
        noIcon,
      };
    },
    created() {
      this.initialDataLoad()
    },
    mounted() {
      this.initTableSorting()
    },
    methods: {
      initialDataLoad() {
        this.loadUsers()
      },
      async loadUsers() {
        const users = await this.$store.dispatch('admin/fetchUsers')

        this.$store.dispatch('admin/setUsers', users)
      },
      initTableSorting() {
        new Tablesort(this.$refs.usersTable, {
          descending: true,
        })
      },
      iconBool(isAdmin) {
        if (isAdmin) {
          return this.yesIcon
        } else {
          return this.noIcon
        }
      },
      cleanUsername(username) {
        return username.replace(/\.law\.harvard\.edu|\.harvard\.edu/g, '')
      },
      deleteUser(user) {
        const that = this

        Swal.fire({
          title: 'Removing User',
          text: `Are you sure want to remove ${user.email}?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            const response = await this.$store.dispatch('admin/deleteUsers', [user.id])

            if (response.ok) {
              this.awn.success('User has been removed.')
              that.loadUsers()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }
          }
        })
      },
      deleteUsers() {
        const that = this
        const usersIds = this.$store.state.admin.users
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        Swal.fire({
          title: 'Removing Users',
          text: `Are you sure want to remove selected users?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            const response = await this.$store.dispatch('admin/deleteUsers', usersIds)

            if (response.ok) {
              this.awn.success('Selected users have been removed.')
              that.loadUsers()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }
          }
        })
      },
      async toggleAdminUsers() {
        const usersIds = this.$store.state.admin.users
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        const response = await this.$store.dispatch('admin/toggleAdminUsers', usersIds)

        if (response.ok) {
          this.awn.success('Selected users have been modified.')
          this.loadUsers()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }
      },
      async sudo() {
        const usersIds = this.$store.state.admin.users
              .filter(user => user.selected)
              .map(user => user.id)

        if (usersIds.length === 0) {
          this.awn.warning('No users selected.')

          return
        }

        const response = await this.$store.dispatch('admin/sudo', usersIds)

        if (response.ok) {
          const user = await this.$store.dispatch('shared/fetchUser')

          this.$store.dispatch('shared/setUser', user)
          this.awn.success('You can now see timesheets of selected users.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }
      },
      toggleAll() {
        const newStatus = this.$refs.toggleAllCheckbox.checked

        this.$store.state.admin.users
          .map((user) => {
            user.selected = newStatus

            return user
          })
      },
    },
  }
</script>

<style lang="scss">
  .admin-users {
    table.table {
      td {
        word-break: break-word;
        vertical-align: middle;
      }

      input[type=checkbox] {
        transform: scale(2);
        cursor: pointer;
      }

      &.table-hovered {
        tbody {
          tr:hover {
            background-color: #e4e4e4;

            td {
              background-color: #e4e4e4;
            }
          }
        }
      }
    }
  }
</style>
