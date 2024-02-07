<template>
  <div class="content admin-timesheets-form">
    <h4 class="is-size-4">{{ title }}</h4>

    <form class="form" @submit.prevent="save">
      <div class="field">
        <label class="label">Name</label>
        <div class="control">
          <input class="input" type="text" v-model="$store.state.admin.timesheet.name" required="true" ref="name">
        </div>
      </div>

      <div class="field is-grouped">
        <div class="control">
          <button class="button is-success" ref="submitButton">Save</button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'

  export default {
    name: 'AdminTimesheetsForm',
    components: {
      Icon,
    },
    data() {
      return {}
    },
    computed: {
      title() {
        if (this.$route.params.id) {
          return 'Edit timesheet'
        } else {
          return 'New timesheet'
        }
      }
    },
    created() {
      this.$store.dispatch('admin/clearTimesheet')
      this.initialDataLoad()
    },
    mounted() {
      this.$refs.name.focus()
    },
    methods: {
      initialDataLoad() {
        this.loadTimesheet()
      },
      async loadTimesheet() {
        if (this.$route.params.id) {
          this.mitt.emit('spinnerStart')

          const response = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.id)

          this.$store.dispatch('admin/setTimesheet', response)

          this.mitt.emit('spinnerStop')
        }
      },
      async save() {
        this.mitt.emit('spinnerStart')
        this.$refs.submitButton.disabled = true

        const response = await this.$store.dispatch('admin/saveTimesheet', this.$store.state.admin.timesheet)

        if (response?.ok) {
          this.awn.success('Timesheet has been saved.')
          this.$router.push({
            path: '/admin/timesheets'
          })
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
        this.$refs.submitButton.disabled = false
      },
    },
  }
</script>

<style lang="scss">
</style>
