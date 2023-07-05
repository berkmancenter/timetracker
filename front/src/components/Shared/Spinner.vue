<template>
  <div class="timetracker-spinner" v-if="running"></div>
</template>

<script>
  export default {
    name: 'Spinner',
    data () {
      return {
        running: false,
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
    border-radius: 50%;
    margin-right: 1rem;
    border: 6px solid #890309;
    animation: spinner-clip 0.96s infinite linear alternate,
               spinner-trans 1.92s infinite linear;
  }

  @keyframes spinner-clip {
    0% {
      clip-path: polygon(50% 50%, 0 0, 50% 0%, 50% 0%, 50% 0%, 50% 0%, 50% 0%);
    }

    12.5% {
      clip-path: polygon(50% 50%, 0 0, 50% 0%, 100% 0%, 100% 0%, 100% 0%, 100% 0%);
    }

    25% {
      clip-path: polygon(50% 50%, 0 0, 50% 0%, 100% 0%, 100% 100%, 100% 100%, 100% 100%);
    }

    50% {
      clip-path: polygon(50% 50%, 0 0, 50% 0%, 100% 0%, 100% 100%, 50% 100%, 0% 100%);
    }

    62.5% {
      clip-path: polygon(50% 50%, 100% 0, 100% 0%, 100% 0%, 100% 100%, 50% 100%, 0% 100%);
    }

    75% {
      clip-path: polygon(50% 50%, 100% 100%, 100% 100%, 100% 100%, 100% 100%, 50% 100%, 0% 100%);
    }

    100% {
      clip-path: polygon(50% 50%, 50% 100%, 50% 100%, 50% 100%, 50% 100%, 50% 100%, 0% 100%);
    }
  }

  @keyframes spinner-trans {
    0% {
      transform: scaleY(1) rotate(0deg);
    }

    49.99% {
      transform: scaleY(1) rotate(135deg);
    }

    50% {
      transform: scaleY(-1) rotate(0deg);
    }

    100% {
      transform: scaleY(-1) rotate(-135deg);
    }
  }
</style>
