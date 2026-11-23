<template>
  <div class="timetracker-spinner" v-if="running">
    <img :src="loaderGif">
  </div>
</template>

<script>
  import loaderGif from '@/images/loader.gif'

  export default {
    name: 'Spinner',
    data () {
      return {
        running: false,
        loaderGif: loaderGif,
      }
    },
    created() {
      this.mitt.on('spinnerStart', this.start)
      this.mitt.on('spinnerStop', this.stop)
    },
    beforeUnmount() {
      this.mitt.off('spinnerStart', this.start)
      this.mitt.off('spinnerStop', this.stop)
    },
    methods: {
      start() {
        this.running = true
      },
      stop() {
        this.running = false
      },
    },
  }
</script>

<style lang="scss">
  .timetracker-spinner {
    width: 2rem;
    height: 2rem;
    margin: 0 0.5rem;
  }
</style>
