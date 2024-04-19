<template>
  <div class="tracker-entry-form-field field">
    <div class="field-label is-normal mb-2">
      <label class="label no-select" :for="id">
        {{ label }}
        <span v-if="required" class="tracker-entry-form-field-required">*</span>
        <span v-if="fieldTagColorVariable" class="tracker-entry-form-field-tag" :style="{ 'background-color': `var(${fieldTagColorVariable})` }">{{ label[0] }}</span>
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
    fieldTagColorVariable: {
      type: String,
      required: false,
    },
    id: {
      type: String,
      required: false,
    },
  },
};
</script>

<style lang="scss">
  .tracker-entry-form-field {
    .accesskey {
      color: #cccccc;
    }

    label {
      display: flex;
      align-items: center;
    }

    .tracker-entry-form-field-required {
      color: rgb(224, 81, 81);
    }

    .tracker-entry-form-field-tag {
      color: #fff;
      border-radius: 0.5rem;
      margin-right: 1rem;
      margin-left: 0.5rem;
      height: 1.5rem;
      width: 1.5rem;
      min-width: 2rem;
      min-height: 2rem;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: normal;
    }
  }
</style>
