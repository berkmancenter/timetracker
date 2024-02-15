<template>
  <VueFinalModal class="tracker-modal" content-class="tracker-modal-content" overlay-transition="vfm-fade" content-transition="vfm-fade">
    <div class="tracker-modal-title is-size-4">
      {{ title }}
    </div>

    <div class="tracker-modal-content-slot mt-5">
      <slot />
    </div>

    <div class="tracker-modal-buttons mt-5">
      <button class="button is-success" @click="$emit('confirm')">
        {{ confirmButtonTitle }}
      </button>

      <button class="button ml-2" @click="$emit('cancel')">
        Cancel
      </button>
    </div>
  </VueFinalModal>
</template>

<script>
  import { VueFinalModal } from 'vue-final-modal'

  export default {
    name: 'Modal',
    props: {
      title: {
        type: String,
        required: true,
      },
      confirmButtonTitle: {
        type: String,
        required: false,
        default: 'Confirm',
      },
    },
    components: {
      VueFinalModal,
    },
  }
</script>

<style lang="scss">
  .tracker-modal {
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .tracker-modal-title {
    border-radius: 1rem;
    box-shadow: rgba(17, 18, 54, 0.16) 0px 1px 4px 0px;
    padding: 0.25rem 1rem;
  }

  .tracker-modal-content {
    padding: 1rem;
    background: #ffffff;
    border-radius: 0.5rem;
    width: 32em;
    max-width: 100%;
  }

  .tracker-modal-content > * + *{
    margin: 0.5rem 0;
  }

  .dark .tracker-modal-content {
    background: #000000;
  }
</style>
