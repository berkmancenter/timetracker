<template>
  <div class="tracker-entry-form-field field">
    <div class="field-label is-normal mb-2">
      <label class="label no-select">
        {{ label }}
        <span v-if="required" class="tracker-entry-form-field-required">*</span>
      </label>
    </div>
    <div class="field-body">
      <div class="field">
        <div class="control">
          <slot></slot>
          <span class="accesskey">alt-{{ accessKey }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'FormField',
  props: {
    label: {
      type: String,
      required: true,
    },
    accessKey: {
      type: String,
      default: '',
    },
    required: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<style lang="scss">
  .tracker-entry-form-field {
    .accesskey {
      color: #cccccc;
    }

    .field-label {
      text-align: left;
    }

    .tracker-entry-form-field-required {
      color: rgb(224, 81, 81);
    }
  }
</style>
