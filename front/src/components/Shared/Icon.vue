<template>
  <img class="tracker-icon" :class="{ 'tracker-icon-interactive': interactive }" :src="src">
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
  }
</script>

<style lang="scss">
  img.tracker-icon {
    max-width: 2.5rem;
    max-height: 100%;
    padding: 0.5rem;
    vertical-align: middle;
    user-select: none;

    &-interactive {
      cursor: pointer;
    }
  }
</style>
