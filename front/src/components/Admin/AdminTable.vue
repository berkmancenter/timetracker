<template>
  <div class="admin-table-wrapper">
    <table class="table table-hovered admin-table" :class="tableClasses" :ref="tableRefName">
      <slot></slot>
    </table>
  </div>
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
        this.initNumberSorting()

        new Tablesort(this.$refs[this.tableRefName], {
          descending: true,
        })
      },
      initNumberSorting() {
        // Copied from tablesort.number.js as it doesn't work with ES6 modules

        let cleanNumber = function(i) {
          return i.replace(/[^\-?0-9.]/g, '')
        }

        let compareNumber = function(a, b) {
          a = parseFloat(a)
          b = parseFloat(b)

          a = isNaN(a) ? 0 : a
          b = isNaN(b) ? 0 : b

          return a - b
        }

        Tablesort.extend('number', function(item) {
          return item.match(/^[-+]?[£\x24Û¢´€]?\d+\s*([,\.]\d{0,2})/) || // Prefixed currency
            item.match(/^[-+]?\d+\s*([,\.]\d{0,2})?[£\x24Û¢´€]/) || // Suffixed currency
            item.match(/^[-+]?(\d)*-?([,\.]){0,1}-?(\d)+([E,e][\-+][\d]+)?%?$/) // Number
        }, function(a, b) {
          a = cleanNumber(a)
          b = cleanNumber(b)

          return compareNumber(b, a)
        })
      },
    },
  }
</script>

<style lang="scss">
  @import '@/assets/scss/admin-table.scss'
</style>
