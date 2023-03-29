<template>
  <img class="tracker-icon" :class="{ 'tracker-icon-interactive': interactive }" :src="iconSrc">
</template>

<script>
  export default {
    props: {
      src: {
        type: String,
        required: true,
      },
      interactive: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    computed: {
      iconSrc() {
        const path = new URL('@/images/', import.meta.url)
        return `${path}/${this.src}`
      }
    }
  }
</script>

<style lang="scss">
  img.tracker-icon {
    max-width: 3rem;
    max-height: 100%;
    padding: 0.5rem;
    vertical-align: middle;

    &-interactive {
      cursor: pointer;
    }

    &-interactive:hover {
      background-color: #fff;
    }
  }
</style>
