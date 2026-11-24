<template>
  <VueDatePicker
    class="tracker-datepicker"
    :model-value="modelValue || null"
    @update:model-value="$emit('update:modelValue', $event || '')"
    model-type="MMMM d, yyyy"
    :formats="{ input: 'MMMM d, yyyy' }"
    :time-config="{ enableTimePicker: false }"
    :text-input="{ format: 'MMMM d, yyyy' }"
    :input-attrs="inputAttrs"
    :ui="{ input: 'input' }"
    :auto-apply="true"
    :teleport="true"
  />
</template>

<script>
  import { VueDatePicker } from '@vuepic/vue-datepicker'

  export default {
    name: 'DatePicker',
    components: {
      VueDatePicker,
    },
    props: {
      modelValue: {
        type: String,
        default: '',
      },
      name: {
        type: String,
        default: undefined,
      },
      id: {
        type: String,
        default: undefined,
      },
      required: {
        type: Boolean,
        default: false,
      },
      accessKey: {
        type: String,
        default: undefined,
      },
    },
    emits: ['update:modelValue'],
    computed: {
      inputAttrs() {
        return {
          clearable: false,
          required: this.required,
          name: this.name,
          id: this.id,
        }
      },
    },
    mounted() {
      if (this.accessKey) {
        this.$el.querySelector('input')?.setAttribute('accesskey', this.accessKey)
      }
    },
  }
</script>
