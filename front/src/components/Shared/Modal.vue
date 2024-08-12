<template>
  <VueFinalModal class="tracker-modal" content-class="tracker-modal-content" overlay-transition="vfm-fade" content-transition="vfm-fade" @opened="opened()">
    <div class="tracker-modal-title is-size-4">
      {{ title }}
    </div>

    <div class="tracker-modal-content-slot mt-5">
      <slot />
    </div>

    <div class="tracker-modal-buttons pt-5 mt-5">
      <button class="tracker-modal-buttons-confirm button is-success ld-ext-right" :class="{ running: working }" accesskey="s" @click="$emit('confirm')" ref="confirmButton">
        {{ confirmButtonTitle }}
        <div class="ld ld-ring ld-spin"></div>
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
    data() {
      return {
        working: false,
      }
    },
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
      focusOnConfirm: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    components: {
      VueFinalModal,
    },
    created() {
      this.mitt.on('modalIsWorking', () => { this.working = true })
      this.mitt.on('modalIsNotWorking', () => { this.working = false })
    },
    methods: {
      opened() {
        if (this.focusOnConfirm && this.$refs.confirmButton) {
          this.$refs.confirmButton.focus()
        }
      },
    },
  }
</script>

<style lang="scss">
  .tracker-modal {
    display: flex;
    justify-content: center;
    align-items: center;
    overflow-y: auto;
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

  .tracker-modal-buttons {
    border-top: 1px solid var(--grey-from-bulma);

    .tracker-modal-buttons-confirm {
      &.button.is-success:focus:not(:active),
      &.button.is-success.is-focused:not(:active) {
        box-shadow: 0 0 0 0.4rem #48c78e40;
      }
    }
  }
</style>
