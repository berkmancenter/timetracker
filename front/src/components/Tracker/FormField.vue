<template>
  <div class="tracker-entry-form-field field">
    <div class="field-label is-normal mb-2">
      <label class="label no-select">{{ label }}</label>
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
  }
</style>
