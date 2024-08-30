<template>
  <div v-if="filteredFields.length > 0">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Popular</h5>

    <div
      v-for="field in filteredFields"
      :key="field.machine_name"
      class="switmenu-section-content"
    >
      <popular-items
        :title="field.title"
        :type="field.machine_name"
        :items="popularItems[field.machine_name]"
        v-if="popularItems[field.machine_name]"
      ></popular-items>
    </div>
  </div>
</template>

<script>
  import PopularItems from './PopularItems.vue'

  export default {
    name: 'Popular',
    components: {
      PopularItems,
    },
    computed: {
      filteredFields() {
        const timesheetFields = this.$store.state.tracker?.selectedTimesheet?.timesheet_fields || []
        return timesheetFields.filter(field => field.popular)
      },
      popularItems() {
        return this.$store.state.tracker?.popular || {}
      },
    }
  }
</script>
