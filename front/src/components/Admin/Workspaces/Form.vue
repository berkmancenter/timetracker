<template>
  <div class="content admin-workspaces-form">
    <h1 class="is-size-1">{{ title }}</h1>

    <form class="form" @submit.prevent="save">
      <div class="field">
        <label class="label">Name</label>
        <div class="control">
          <input class="input" type="text" v-model="$store.state.admin.workspace.name" required="true">
        </div>
      </div>

      <div class="field is-grouped">
        <div class="control">
          <button class="button">Save</button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'

  export default {
    name: 'AdminWorkspacesForm',
    components: {
      Icon,
    },
    data() {
      return {}
    },
    computed: {
      title() {
        if (this.$route.params.id) {
          return 'Edit workspace'
        } else {
          return 'New workspace'
        }
      }
    },
    created() {
      this.$store.dispatch('admin/clearWorkspace')
      this.initialDataLoad()
    },
    methods: {
      initialDataLoad() {
        this.loadWorkspace()
      },
      async loadWorkspace() {
        if (this.$route.params.id) {
          this.mitt.emit('spinnerStart')

          const response = await this.$store.dispatch('admin/fetchWorkspace', this.$route.params.id)

          this.$store.dispatch('admin/setWorkspace', response)

          this.mitt.emit('spinnerStop')
        }
      },
      async save() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/saveWorkspace', this.$store.state.admin.workspace)

        if (response?.ok) {
          this.awn.success('Workspace has been saved.')
          this.$router.push({
            path: '/admin/workspaces'
          })
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
    },
  }
</script>

<style lang="scss">
</style>
