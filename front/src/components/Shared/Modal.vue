<template>
  <VueFinalModal class="tracker-modal" content-class="tracker-modal-content" overlay-transition="vfm-fade" content-transition="vfm-fade" @opened="opened()">
    <div class="tracker-modal-title is-size-4">
      <div class="tracker-modal-title-text">{{ title }}</div>
      <div class="tracker-modal-title-close" @click="$emit('cancel')">
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
  $tm: "tracker-modal";

  .#{$tm} {
    display: flex;
    justify-content: center;
    align-items: center;
    overflow-y: auto;

    .vfm--overlay {
      background: rgba(35, 36, 41, 0.7);
    }

    &-title {
      background-color: var(--main-color);
      color: #ffffff;
      display: flex;
      height: 3.5rem;
      align-items: center;

      &-text {
        padding-left: 1rem;
      }

      &-close {
        height: 3.5rem;
        width: 3.5rem;
        margin-left: auto;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;

        img {
          padding: 0;
          height: 2rem;
          width: 2rem;

          &:hover {
            background-color: unset;
          }
        }

        &:hover {
          background-color: rgba(255, 255, 255, 0.1);
        }
      }
    }

    &-content {
      background: #ffffff;
      border-radius: 0.5rem;
      width: 32em;
      max-width: 100%;

      &-wrapper {
        padding: 1rem;
      }

      > * + * {
        margin: 0.5rem 0;
      }

      .dark & {
        background: #000000;
      }
    }

    &-buttons {
      border-top: 1px solid var(--grey-from-bulma);

      &-confirm {
        &.button.is-success {
          &:focus:not(:active),
          &.is-focused:not(:active) {
            box-shadow: 0 0 0 0.4rem rgba(72, 199, 142, 0.25);
          }
        }
      }
    }
  }
</style>
