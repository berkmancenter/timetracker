<template>
  <component
    :is="tagName"
    class="tracker-action-button button"
    :class="{
      'tracker-action-button-active': active,
      'tracker-action-button-icon-left': iconPosition === 'left' && hasButtonText,
      'tracker-action-button-icon-right': iconPosition === 'right' && hasButtonText,
      'is-disabled': disabled,
    }"
    @click="handleClick"
    :disabled="button && disabled ? true : null"
    :aria-disabled="disabled ? 'true' : null"
    :tabindex="!button && disabled ? -1 : null"
  >
    <Icon :src="icon" :interactive="false" v-if="icon && iconPosition === 'left'" />
    <div>{{ buttonText }}</div>
    <Icon :src="icon" :interactive="false" v-if="icon && iconPosition === 'right'" />
  </component>
</template>

<script>
import Icon from '@/components/Shared/Icon.vue'

export default {
  components: {
    Icon,
  },
  props: {
    icon: String,
    buttonText: String,
    onClick: Function,
    iconPosition: {
      type: String,
      default: 'left',
      validator: (value) => ['left', 'right'].includes(value)
    },
    button: {
      type: Boolean,
      required: false,
      default: false,
    },
    active: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tagName() {
      return this.button ? 'button' : 'a'
    },
    hasButtonText() {
      return !!this.buttonText
    }
  },
  methods: {
    handleClick(event) {
      if (this.disabled) {
        event?.preventDefault()
        event?.stopPropagation()
        return
      }

      if (typeof this.onClick === 'function') {
        this.onClick(event)
      }
    },
  },
}
</script>

<style lang="scss">
.tracker-action-button {
  padding: 0.5rem 0.5rem;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;

  &.is-disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  > * {
    height: 100%;
  }

  &.tracker-action-button-active {
    background-color: var(--super-light-color);
  }

  > img {
    height: 1.5rem !important;
  }

  &:not(.tracker-action-button-icon-right) {
    &.tracker-action-button-icon-left img {
      margin-left: 0 !important;
      margin-right: 0.25rem !important;
    }
  }

  &.tracker-action-button-icon-right img {
    margin-left: 0.25rem !important;
    margin-right: 0 !important;
  }

  &:not(.tracker-action-button-icon-left):not(.tracker-action-button-icon-right) {
    img {
      margin: 0 !important;
    }
  }
}
</style>
