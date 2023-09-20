<template>
  <table class="table table-hovered admin-table" :class="tableClasses" :ref="tableRefName">
    <slot></slot>
  </table>
</template>

<script>
  import 'tablesort/tablesort.css'
  import Tablesort from 'tablesort'

  export default {
    name: 'AdminTable',
    props: {
      tableRefName: {
        type: String,
        required: false,
        default: 'adminTable',
      },
      tableClasses: {
        type: Array,
        required: false,
        default: [],
      },
    },
    mounted() {
      this.initTableSorting()
    },
    methods: {
      initTableSorting() {
        new Tablesort(this.$refs[this.tableRefName], {
          descending: true,
        })
      },
    },
  }
</script>

<style lang="scss">
  @import '@/assets/scss/admin-table.scss'
</style>
