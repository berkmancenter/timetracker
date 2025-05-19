<template>
  <div class="field custom-fields">
    <label class="label">Fields</label>

    <div class="notification" v-if="filteredFields.length < minRequiredFields">
      You need at least {{ minRequiredFields }} field{{ minRequiredFields !== 1 ? 's' : '' }} to be able to save.
    </div>

    <div class="custom-fields-field" v-for="(field, index) in filteredFields" :key="field.id || index">
      <div class="field">
        <label class="label" :for="`field-title-${index}`">Title</label>
        <div class="control">
          <input class="input" type="text" v-model="field.title" required="true" :id="`field-title-${index}`">
        </div>
      </div>

      <div class="field">
        <label class="label" :for="`field-type-${index}`">Type</label>
        <div class="control">
          <div class="select">
            <select v-model="field.input_type" required="true" :id="`field-type-${index}`">
              <option value="text">
                Short text
              </option>
              <option value="long_text">
                Long text
              </option>
            </select>
          </div>
        </div>
      </div>

      <div class="field">
        <label class="label" :for="`field-popular-${index}`">Show top values in sidebar</label>
        <div class="control">
          <div class="select">
            <select v-model="field.popular" required="true" :id="`field-popular-${index}`">
              <option :value="true">
                Yes
              </option>
              <option :value="false">
                No
              </option>
            </select>
          </div>
        </div>
      </div>

      <div class="field">
        <label class="label" :for="`field-list-${index}`">Show in table</label>
        <div class="control">
          <div class="select">
            <select v-model="field.list" required="true" :id="`field-list-${index}`">
              <option :value="true">
                Yes
              </option>
              <option :value="false">
                No
              </option>
            </select>
          </div>
        </div>
      </div>

      <div class="field">
        <label class="label" :for="`field-access-key-${index}`">Access key</label>
        <div class="control">
          <input class="input" type="text" v-model="field.access_key" :id="`field-access-key-${index}`">
        </div>
      </div>

      <hr>

      <div>
        <a title="Remove field" @click.prevent="removeField(field)">
          <Icon :src="minusIcon" />
        </a>
        <a title="Move up" @click.prevent="moveField(field, -1)" v-if="field.order > 1">
          <Icon :src="upIcon" />
        </a>
        <a title="Move down" @click.prevent="moveField(field, 1)" v-if="field.order != filteredFields.length">
          <Icon :src="downIcon" />
        </a>
      </div>
    </div>

    <div class="ml-4">
      <a class="has-text-danger custom-fields-add" title="Add new field" @click.prevent="addField()">
        <Icon :src="addIcon" />
      </a>
    </div>
  </div>
</template>

<script>
import Icon from '@/components/Shared/Icon.vue'
import minusIcon from '@/images/minus_main.svg'
import addIcon from '@/images/add_main.svg'
import upIcon from '@/images/up_main.svg'
import downIcon from '@/images/down_main.svg'
import orderBy from 'lodash/orderBy'

export default {
  name: 'CustomFields',
  components: {
    Icon,
  },
  props: {
    fields: {
      type: Array,
      required: true,
      default: () => [],
    },
    modelName: {
      type: String,
      default: 'timesheet',
    },
    minRequiredFields: {
      type: Number,
      default: 0,
    }
  },
  data() {
    return {
      minusIcon,
      addIcon,
      upIcon,
      downIcon,
    }
  },
  computed: {
    filteredFields() {
      let customFields = [...this.fields]
      customFields = orderBy(customFields, ['order'], ['asc'])

      return customFields.filter(field => !field._destroy)
    },
  },
  methods: {
    addField() {
      this.$store.dispatch('admin/addCustomField', this.modelName)
    },
    removeField(field) {
      this.$store.dispatch('admin/removeCustomField', { field, modelName: this.modelName })
    },
    moveField(field, direction) {
      const previousField = this.filteredFields.find(f => f.order === field.order + direction)
      if (previousField) {
        previousField.order = field.order
      }

      field.order += direction

      const nextField = this.filteredFields.find(f => f.order === field.order - direction)
      if (nextField) {
        nextField.order = field.order - direction
      }

      // Emit an event to notify parent component fields have been reordered
      this.$emit('fields-reordered', this.filteredFields)
    },
  },
}
</script>

<style lang="scss">
  .custom-fields {
    &-field {
      border: 1px solid #dbdbdb;
      border-radius: 5px;
      padding: 1rem;
      margin-bottom: 1rem;
      max-width: 500px;

      hr {
        margin: 1rem 0;
      }
    }

    .tracker-icon {
      width: 3rem;
      height: 3rem;

      &:hover {
        transform: scale(1.1);
      }
    }

    /* Silly, but icon is from the same family set, but has a different size */
    &-add {
      .tracker-icon {
        width: 3.2rem;
        height: 3.2rem;
        max-width: 3.2rem;
      }
    }
  }
</style>
