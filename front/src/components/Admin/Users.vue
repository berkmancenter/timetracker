<template>
  <div class="content admin-users">
    <h1 class="is-size-1">Users</h1>

    <form class="form">
      <div class="mb-4">
        <a class="button is-danger mr-2" @click="deleteUsers()">Remove selected</a>
        <a class="button is-info" @click="toggleAdminUsers()">Toggle admin selected</a>
      </div>

      <table class="table table-hovered users-index-table">
        <thead>
          <tr>
            <th>
              <input type="checkbox">
            </th>
            <th>Username</th>
            <th>Email</th>
            <th>Admin</th>
            <th>Created</th>
            <th>Actions</th>
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
              <Icon :src="iconBool(user.superadmin)" />
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
    methods: {
      initialDataLoad() {
        this.loadUsers()
      },
      async loadUsers() {
        const users = await this.$store.dispatch('admin/fetchUsers')

        this.$store.dispatch('admin/setUsers', users)
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
