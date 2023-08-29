<template>
  <div class="content timesheets-invitations-join">
    <h1 class="is-size-1 has-text-centered">Please wait</h1>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'

  export default {
    name: 'TimesheetsInvitationJoin',
    components: {
      Icon,
    },
    data() {
      return {}
    },
    created() {
      this.setJoinLayout()
    },
    mounted() {
      this.join()
    },
    methods: {
      async join() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('tracker/joinTimesheet', this.$route.params.code)

        if (response.ok) {
          this.awn.success('You have joined successfully.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.$router.push({
          name: 'tracker.index',
        })

        this.setTrackerLayout()

        this.mitt.emit('spinnerStop')
      },
      setJoinLayout() {
        this.$store.dispatch('shared/setSideMenuEnabled', false)
        this.$store.dispatch('shared/setSideMenuStatus', false)
      },
      setTrackerLayout() {
        this.$store.dispatch('shared/setSideMenuEnabled', true)
        this.$store.dispatch('shared/setSideMenuStatus', true)
      },
    },
  }
</script>

<style lang="scss">
</style>
