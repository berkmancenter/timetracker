<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

  <div class="content admin-periods-form">
    <h4 class="is-size-4">{{ title }}</h4>

    <form class="form" @submit.prevent="save">
      <div class="field">
        <label class="label">Name</label>
        <div class="control">
          <input class="input" type="text" v-model="$store.state.admin.period.name" required="true">
        </div>
      </div>

      <div class="field">
        <label class="label">From</label>
        <div class="control">
          <date-picker v-model:value="$store.state.admin.period.from" format="MMMM D, Y" type="date" value-type="format" input-class="input" :clearable="false" :input-attr="{ required: true }" name="from"></date-picker>
        </div>
      </div>

      <div class="field">
        <label class="label">To</label>
        <div class="control">
          <date-picker v-model:value="$store.state.admin.period.to" format="MMMM D, Y" type="date" value-type="format" input-class="input" :clearable="false" :input-attr="{ required: true }" name="to"></date-picker>
        </div>
      </div>

      <div class="box">
        <CustomFields
          :fields="$store.state.admin.period.custom_fields"
          model-name="period"
          :types="[
            { value: 'text', label: 'Short text' },
          ]"
        ></CustomFields>
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
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'
  import CustomFields from '@/components/Shared/CustomFields.vue'

  export default {
    name: 'AdminPeriodsForm',
    components: {
      Icon,
      Breadcrumbs,
      CustomFields,
    },
    data() {
      return {
        timesheets: [],
      }
    },
    computed: {
      title() {
        if (this.$route.params.id) {
          return 'Edit period'
        } else {
          return 'New period'
        }
      },
      breadcrumbs() {
        let breadcrumbs = []

        breadcrumbs.push({
          text: 'Timesheets',
          link: '/admin/timesheets',
        })

        breadcrumbs.push({
          text: this.$store.state.admin?.timesheet?.name,
        })

        breadcrumbs.push({
          text: 'Periods',
          link: `/admin/timesheets/${this.$store.state.admin?.timesheet?.id}/periods`,
        })

        if (this.$route.params.id) {
          breadcrumbs.push({
            text: this.$store.state.admin?.period?.name,
          })

          breadcrumbs.push({
            text: 'Edit period',
          })
        } else {
          breadcrumbs.push({
            text: 'New period',
          })
        }

        return breadcrumbs
      },
    },
    created() {
      this.$store.dispatch('admin/clearPeriod')
      this.initialDataLoad()
    },
    methods: {
      async initialDataLoad() {
        this.timesheets = await this.$store.dispatch('admin/fetchAdminTimesheets')
        const timesheet = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.timesheet_id)
        this.$store.dispatch('admin/setTimesheet', timesheet)

        if (this.$route.params.id) {
          this.mitt.emit('spinnerStart')

          const response = await this.$store.dispatch('admin/fetchPeriod', {
            timesheetId: this.$route.params.timesheet_id,
            periodId: this.$route.params.id,
          })

          response.from = new Date(response.from).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          })

          response.to = new Date(response.to).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          })

          this.$store.dispatch('admin/setPeriod', response)

          this.mitt.emit('spinnerStop')
        }
      },
      async save() {
        this.mitt.emit('spinnerStart')
        this.$refs.submitButton.disabled = true
        this.$store.state.admin.period.timesheet_id = this.$route.params.timesheet_id

        const response = await this.$store.dispatch('admin/savePeriod', {
          timesheet_id: this.$route.params.timesheet_id,
          period: this.$store.state.admin.period,
        })

        if (response?.ok) {
          this.awn.success('Period has been saved.')
          this.$router.push({
            path: `/admin/timesheets/${this.$route.params.timesheet_id}/periods`,
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
