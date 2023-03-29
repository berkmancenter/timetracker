<template>
  <div class="field is-horizontal">
    <div class="field-label is-normal">
      <label class="label">{{ label }}</label>
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

<style scoped lang="scss">
  .accesskey {
    color: #cccccc;
  }
</style>
