<template>
  <VueFinalModal
    class="timetracker-modal"
    content-class="timetracker-modal-content"
    overlay-transition="vfm-fade"
    content-transition="vfm-fade"
    @opened="opened()"
    @closed="closed()"
    :clickOutside="clickOutside"
  >
    <div class="timetracker-modal-title is-size-4">
      <div class="timetracker-modal-title-text">{{ title }}</div>
      <div class="timetracker-modal-title-close" @click="$emit('cancel')">
        <Icon :src="closeIcon" />
      </div>
    </div>

    <div class="timetracker-modal-content-wrapper">
      <div class="timetracker-modal-content-slot">
        <slot />
      </div>

      <div class="timetracker-modal-buttons pt-5 mt-5">
        <button class="timetracker-modal-buttons-confirm button is-success ld-ext-right" :class="{ running: working }" v-if="showConfirmButton" accesskey="s" @click="$emit('confirm')" ref="confirmButton">
          {{ confirmButtonTitle }}
          <div class="ld ld-ring ld-spin"></div>
        </button>

        <button class="button ml-2" @click="$emit('cancel')" v-if="showCancelButton">
          {{ cancelButtonTitle }}
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
      cancelButtonTitle: {
        type: String,
        required: false,
        default: 'Cancel',
      },
      focusOnConfirm: {
        type: Boolean,
        required: false,
        default: true,
      },
      showConfirmButton: {
        type: Boolean,
        required: false,
        default: true,
      },
      showCancelButton: {
        type: Boolean,
        required: false,
        default: true,
      },
      clickOutside: {
        type: Function,
        required: false,
        default: () => {},
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
        document.querySelector('html').style.overflow = 'hidden'

        if (this.focusOnConfirm && this.$refs.confirmButton) {
          this.$refs.confirmButton.focus()
        }
      },
      closed() {
        document.querySelector('html').style.overflow = 'auto'
      },
    },
  }
</script>

<style lang="scss">
  $tm: "timetracker-modal";

  .#{$tm} {
    display: flex;
    justify-content: center;
    align-items: center;
    overflow-y: auto;
    z-index: 10002 !important;

    @media all and (max-width: 700px) {
      display: block;
      justify-content: unset;
      align-items: unset;
      background-color: #ffffff;
    }

    .vfm--overlay {
      background: rgba(35, 36, 41, 0.7);
    }

    &-title {
      background-color: var(--main-color);
      color: #ffffff;
      display: flex;
      align-items: center;
      user-select: none;
      height: 3.5rem;

      &-text {
        padding: 0.5rem 1rem;
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
      margin: 0 auto;
      position: relative;

      &-wrapper {
        padding: 1rem;
        max-height: calc(100vh - 6.5rem);
        overflow-y: scroll;
        padding-bottom: 6rem;
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
      position: absolute;
      bottom: 0;
      left: 0;
      width: 100%;
      background: #ffffff;
      height: 5.5rem;
      padding: 1rem;

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
