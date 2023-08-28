<template>
  <div class="content admin-periods-form">
    <h1 class="is-size-1">{{ title }}</h1>

    <form class="form" @submit.prevent="save">
      <div class="field">
        <label class="label">Name</label>
        <div class="control">
          <input class="input" type="text" v-model="$store.state.admin.period.name" required="true">
        </div>
      </div>

      <div class="field">
        <label class="label">Timesheet</label>
        <div class="control">
          <div class="select">
            <select v-model="$store.state.admin.period.timesheet_id">
              <option v-for="timesheet in timesheets" :key="timesheet.id" :value="timesheet.id">
                {{ timesheet.name }}
              </option>
            </select>
          </div>
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
    name: 'AdminPeriodsForm',
    components: {
      Icon,
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
      }
    },
    created() {
      this.$store.dispatch('admin/clearPeriod')
      this.initialDataLoad()
    },
    methods: {
      initialDataLoad() {
        this.loadPeriod()
      },
      async loadPeriod() {
        this.timesheets = await this.$store.dispatch('admin/fetchTimesheets')

        if (this.$route.params.id) {
          this.mitt.emit('spinnerStart')

          const response = await this.$store.dispatch('admin/fetchPeriod', this.$route.params.id)

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

        const response = await this.$store.dispatch('admin/savePeriod', this.$store.state.admin.period)

        if (response?.ok) {
          this.awn.success('Period has been saved.')
          this.$router.push({
            path: '/admin/periods'
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
