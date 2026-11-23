<template>
  <div class="content timesheets-invitations-join">
    <h1 class="is-size-1 has-text-centered">Please wait</h1>
  </div>
</template>

<script>
  export default {
    name: 'TimesheetsInvitationJoin',
    mounted() {
      this.join()
    },
    methods: {
      async join() {
        this.mitt.emit('spinnerStart')

        try {
          const response = await this.$store.dispatch('tracker/joinTimesheet', this.$route.params.code)

          if (response.ok) {
            this.awn.success('You have joined successfully.')
          } else {
            this.awn.warning('Something went wrong, try again.')
          }
        } catch {
          this.awn.warning('Something went wrong, try again.')
        } finally {
          this.mitt.emit('spinnerStop')
        }

        this.$router.push({
          name: 'tracker.index',
        })
      },
    },
  }
</script>
