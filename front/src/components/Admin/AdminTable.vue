<template>
  <div class="admin-table-wrapper">
    <table class="table table-hovered admin-table" :class="tableClasses">
      <slot></slot>
    </table>
  </div>
</template>

<script>
  export default {
    name: 'AdminTable',
    props: {
      tableClasses: {
        type: Array,
        required: false,
        default: () => [],
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

    th {
      vertical-align: middle;
    }

    th.admin-table-sortable {
      position: relative;
      padding-right: 1.5rem;
      cursor: pointer;
      user-select: none;

      &::after {
        content: '';
        position: absolute;
        right: 0.5rem;
        top: 50%;
        transform: translateY(-50%);
        border-width: 0 4px 4px;
        border-style: solid;
        border-color: #404040 transparent;
        visibility: hidden;
        opacity: 0.4;
      }

      &:hover::after {
        visibility: visible;
      }

      &[aria-sort='ascending']::after {
        visibility: visible;
        opacity: 0.9;
        border-bottom: none;
        border-width: 4px 4px 0;
      }

      &[aria-sort='descending']::after {
        visibility: visible;
        opacity: 0.9;
      }
    }

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
