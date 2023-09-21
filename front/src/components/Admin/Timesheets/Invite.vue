<template>
  <div class="content admin-timesheets-invitations-form">
    <h4 class="is-size-4">Invitations</h4>

    <div class="mb-4">
      Send invitations for
      <span class="tag is-black is-large">{{ $store.state.admin.timesheet.name }}</span>
      timesheet
    </div>

    <p>When you send out invitations, users will receive emails containing unique invitation links. With these links, they can easily join the timesheet.</p>

    <form class="form" @submit.prevent="send">
      <div class="field">
        <label class="label">
          Emails
          <div class="is-size-7 has-text-weight-normal">One per line or comma/space separated.</div>
        </label>
        <div class="control">
          <textarea class="textarea" v-model="$store.state.admin.timesheetInvitations" required="true" ref="inviteEmails"></textarea>
        </div>
      </div>

      <div class="field is-grouped">
        <div class="control">
          <button class="button" ref="submitButton">Send</button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'

  export default {
    name: 'AdminTimesheetsInvitationsForm',
    components: {
      Icon,
    },
    data() {
      return {}
    },
    created() {
      this.initialDataLoad()
    },
    mounted() {
      this.$refs.inviteEmails.focus()
    },
    methods: {
      initialDataLoad() {
        this.$store.dispatch('admin/setTimesheetInvitations', '')
        this.loadTimesheet()
      },
      async loadTimesheet() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.id)

        this.$store.dispatch('admin/setTimesheet', response)

        this.mitt.emit('spinnerStop')
      },
      async send() {
        this.mitt.emit('spinnerStart')
        this.$refs.submitButton.disabled = true

        const response = await this.$store.dispatch('admin/sendTimesheetInvitations', {
          timesheetId: this.$store.state.admin.timesheet.id,
          emails: this.$store.state.admin.timesheetInvitations,
        })

        if (response?.ok) {
          this.awn.success('Invitations have been sent out.')
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
