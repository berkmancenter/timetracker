<template>
  <div class="content admin-timesheets-form">
    <h4 class="is-size-4">{{ title }}</h4>

    <form class="form" @submit.prevent="save">
      <div class="field">
        <label class="label" for="name">Name</label>
        <div class="control">
          <input class="input" type="text" v-model="$store.state.admin.timesheet.name" required="true" ref="name" name="name" id="name">
        </div>
      </div>

      <div class="field admin-timesheets-form-fields">
        <label class="label">Fields</label>

        <div class="admin-timesheets-form-fields-field" v-for="field in filteredFields" :key="field.id">
          <div class="field">
            <label class="label">Title</label>
            <div class="control">
              <input class="input" type="text" v-model="field.title" required="true">
            </div>
          </div>

          <div class="field">
            <label class="label">Type</label>
            <div class="control">
              <div class="select">
                <select v-model="field.input_type" required="true">
                  <option value="text">
                    Short text
                  </option>
                  <option value="long_text">
                    Long text
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">Show top values in sidebar</label>
            <div class="control">
              <div class="select">
                <select v-model="field.popular" required="true">
                  <option value="true">
                    Yes
                  </option>
                  <option value="false">
                    No
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div class="field">
            <label class="label">Show in time entries table</label>
            <div class="control">
              <div class="select">
                <select v-model="field.list" required="true">
                  <option value="true">
                    Yes
                  </option>
                  <option value="false">
                    No
                  </option>
                </select>
              </div>
            </div>
          </div>

          <div>
            <a title="Remove field" @click.prevent="removeField(field)">
              <Icon :src="minusIcon" />
            </a>
          </div>
        </div>

        <div class="ml-4">
          <a class="has-text-danger" title="Add new field" @click.prevent="addField()">
            <Icon :src="addIcon" />
          </a>
        </div>
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
  import minusIcon from '@/images/minus_light.svg'
  import addIcon from '@/images/add.svg'

  export default {
    name: 'AdminTimesheetsForm',
    components: {
      Icon,
    },
    data() {
      return {
        minusIcon,
        addIcon,
      }
    },
    computed: {
      title() {
        if (this.$route.params.id) {
          return 'Edit timesheet'
        } else {
          return 'New timesheet'
        }
      },
      filteredFields() {
        const timesheetFields = this.$store.state.admin?.timesheet?.timesheet_fields
        return (timesheetFields || []).filter(field => !field._destroy)
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
      addField() {
        this.$store.dispatch('admin/addTimesheetField')
      },
      removeField(field) {
        this.$store.dispatch('admin/removeTimesheetField', field)
      },
    },
  }
</script>

<style lang="scss">
  .admin-timesheets-form-fields-field {
    border: 1px solid #dbdbdb;
    border-radius: 5px;
    padding: 1rem;
    margin-bottom: 1rem;
    max-width: 500px;
  }
</style>
