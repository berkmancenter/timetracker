<template>
  <VueFinalModal class="tracker-modal" content-class="tracker-modal-content" overlay-transition="vfm-fade" content-transition="vfm-fade" @opened="opened()">
    <div class="tracker-modal-title is-size-4">
      <div>{{ title }}</div>
      <div class="tracker-modal-close" @click="$emit('cancel')">
        <Icon :src="closeIcon" />
      </div>
    </div>

    <div class="tracker-modal-content-wrapper">
      <div class="tracker-modal-content-slot">
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
    </div>
  </VueFinalModal>
</template>

<script>
  import { VueFinalModal } from 'vue-final-modal'
  import closeIcon from '@/images/close.svg'
  import Icon from '@/components/Shared/Icon.vue'

  export default {
    name: 'Modal',
    data() {
      return {
        working: false,
        closeIcon,
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
      Icon,
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

    .vfm--overlay {
      background: #232429b3;
    }
  }

  .tracker-modal-title {
    padding: 0.25rem 1rem;
    padding: 1rem;
    background-color: var(--main-color);
    color: #ffffff;
    display: flex;

    .tracker-modal-close {
      height: 1.5rem;
      width: 1.5rem;
      margin-left: auto;

      img {
        padding: 0;

        &:hover {
          background-color: unset;
        }
      }
    }
  }

  .tracker-modal-content {
    background: #ffffff;
    border-radius: 0.5rem;
    width: 32em;
    max-width: 100%;
  }

  .tracker-modal-content-wrapper {
    padding: 1rem
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
