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
      const that = this

      this.mitt.on('spinnerStart', () => that.start())
      this.mitt.on('spinnerStop', () => that.stop())
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
    margin-right: 1rem;
  }
</style>
