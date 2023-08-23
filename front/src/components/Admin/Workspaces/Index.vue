<template>
  <div class="content admin-workspaces">
    <h1 class="is-size-1">Workspaces</h1>

    <form class="form">
      <div class="mb-4">
        <router-link :to="'/admin/workspaces/new'" class="button is-success">Add workspace</router-link>
      </div>

      <admin-table :tableClasses="['admin-workspaces-table']">
        <thead>
          <tr class="no-select">
            <th>Name</th>
            <th data-sort-method="none" class="no-sort">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="workspace in $store.state.admin.workspaces" :key="workspace.id">
            <td>{{ workspace.name }}</td>
            <td>
              <router-link :to="`/admin/workspaces/${workspace.id}/edit`">
                <Icon :src="editIcon" />
              </router-link>
              <a title="Delete this workspace" @click.prevent="deleteWorkspace(workspace)">
                <Icon :src="minusIcon" />
              </a>
            </td>
          </tr>
          <tr v-if="$store.state.admin.workspaces.length === 0">
            <td colspan="7">No workspaces found.</td>
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
    name: 'AdminWorkspaces',
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
        this.loadWorkspaces()
      },
      async loadWorkspaces() {
        this.mitt.emit('spinnerStart')

        const workspaces = await this.$store.dispatch('admin/fetchWorkspaces')

        this.$store.dispatch('admin/setWorkspaces', workspaces)

        this.mitt.emit('spinnerStop')
      },
      deleteWorkspace(workspace) {
        const that = this

        Swal.fire({
          title: 'Removing workspace',
          text: `Are you sure to remove ${workspace.name}?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            this.mitt.emit('spinnerStart')

            const response = await this.$store.dispatch('admin/deleteWorkspaces', [workspace.id])

            if (response.ok) {
              this.awn.success('Workspace has been removed.')
              that.loadWorkspaces()
            } else {
              this.awn.warning('Something went wrong, try again.')
            }

            this.mitt.emit('spinnerStop')
          }
        })
      },
      async cloneWorkspace(workspace) {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/cloneWorkspace', workspace.id)

        if (response.ok) {
          this.awn.success(`Workspace "${workspace.name}" has been cloned.`)
          this.loadWorkspaces()
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
    },
  }
</script>
