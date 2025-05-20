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
      forceSortingRefresh: {
        type: Array,
        required: false,
        default: [],
      },
    },
    data() {
      return {
        tablesort: null,
      }
    },
    mounted() {
      this.initTableSorting()
    },
    methods: {
      initTableSorting() {
        this.initNumberSorting()
        this.initTableSort()
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
      initTableSort() {
        // Check if tablesort is already initialized and remove previous
        // listeners to avoid duplicate sorting. The library doesn't
        // support re-initialization ¯\_(ツ)_/¯.
        if (this.tablesort) {
          const ths = this.$refs[this.tableRefName].querySelectorAll('th')
          ths.forEach(th => {
            // Remove click listeners added by tablesort
            const clone = th.cloneNode(true)
            th.parentNode.replaceChild(clone, th)
          })
        }

        this.tablesort = new Tablesort(this.$refs[this.tableRefName], {
          descending: true,
        })
      },
    },
    watch: {
      forceSortingRefresh: {
        handler() {
          this.$nextTick(() => {
            this.initTableSort()
          })
        },
        deep: true,
      },
    },
  }
</script>

<style lang="scss">
  .admin-table-wrapper {
    overflow-x: auto;
  }

  table.table.admin-table {
    width: 100%;

    td {
      word-break: break-word;
      vertical-align: middle;
    }

    input[type=checkbox] {
      transform: scale(2);
      cursor: pointer;
    }

    &.table-hovered {
      tbody {
        tr:hover {
          background-color: #e4e4e4;

          td {
            background-color: #e4e4e4;
          }
        }
      }
    }
  }

  .admin-table-actions {
    width: 12rem;

    img {
      &:hover {
        background-color: #ffffff;
      }
    }
  }

  .admin-table-selector {
    width: 6rem;
  }
</style>
