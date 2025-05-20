<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

  <div class="content admin-timesheets-form">
    <h4 class="is-size-4">{{ title() }}</h4>

    <form class="form" @submit.prevent="save">
      <div class="box">
        <div class="field">
          <label class="label" for="name">Name</label>
          <div class="control">
            <input class="input" type="text" v-model="$store.state.admin.timesheet.name" required="true" ref="name" name="name" id="name">
          </div>
        </div>
      </div>

      <div class="box">
        <CustomFields
          :fields="$store.state.admin.timesheet.custom_fields"
          model-name="timesheet"
          :min-required-fields="1"
        >
        <template #additional-fields="{ field, index }">
          <!-- Popular field -->
          <div class="field">
            <label class="label" :for="`field-popular-${index}`">Show top values in sidebar</label>
            <div class="control">
              <div class="select">
                <select v-model="field.popular" required="true" :id="`field-popular-${index}`">
                  <option :value="true">Yes</option>
                  <option :value="false">No</option>
                </select>
              </div>
            </div>
          </div>

          <!-- List field -->
          <div class="field">
            <label class="label" :for="`field-list-${index}`">Show in table</label>
            <div class="control">
              <div class="select">
                <select v-model="field.list" required="true" :id="`field-list-${index}`">
                  <option :value="true">Yes</option>
                  <option :value="false">No</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Access key field -->
          <div class="field">
            <label class="label" :for="`field-access-key-${index}`">Access key</label>
            <div class="control">
              <input class="input" type="text" v-model="field.access_key" :id="`field-access-key-${index}`">
            </div>
          </div>
        </template>
        </CustomFields>
      </div>

      <hr>

      <div class="field is-grouped">
        <div class="control">
          <button class="button is-success" ref="submitButton" id="submit" name="submit" title="Submit">Save</button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'
  import CustomFields from '@/components/Shared/CustomFields.vue'

  export default {
    name: 'AdminTimesheetsForm',
    components: {
      Icon,
      Breadcrumbs,
      CustomFields,
    },
    computed: {
      breadcrumbs() {
        let breadcrumbs = []

        breadcrumbs.push({
          text: 'Timesheets',
          link: '/admin/timesheets',
        })

        if (this.$route.params.id) {
          breadcrumbs.push({
            text: this.$store.state.admin.timesheet.name,
          })
          breadcrumbs.push({
            text: 'Edit timesheet',
          })
        } else {
          breadcrumbs.push({
            text: 'New timesheet',
          })
        }

        return breadcrumbs
      },
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
        if (this.$store.state.admin.timesheet.custom_fields.length === 0 || 
            this.$store.state.admin.timesheet.custom_fields.every(field => field._destroy)) {
          this.awn.warning('You need at least 1 field to be able to save the timesheet.')
          return
        }

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
      title() {
        if (this.$route.params.id) {
          return 'Edit timesheet'
        } else {
          return 'New timesheet'
        }
      },
    },
  }
</script>
