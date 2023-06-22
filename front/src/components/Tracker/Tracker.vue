<template>
  <div>
    <entry-form></entry-form>
    <entries></entries>
  </div>
</template>

<script>
  import EntryForm from './EntryForm.vue'
  import Entries from './Entries.vue'

  export default {
    name: 'TrackerLayout',
    components: {
      EntryForm,
      Entries,
    },
    data() {
      return {}
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      async initialDataLoad() {
        const months = await this.$store.dispatch('tracker/fetchMonths')

        this.$store.dispatch('tracker/setMonths', months)
        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'entries', 'dailyTotals'])
      }
    },
  }
</script>

<style lang="scss">
  footer#footer {
    background: var(--main-color);
    padding: 1rem;
    clear: both;
    border-style: solid none none none;
    text-align: center;
    color: #ffffff;
    font-weight: bold;
    margin-top: 2rem;
  }
  h3.logo {
    color: var(--main-color);
  }

  div.navbar-brand {
    img {
      height: 1.5rem;
    }
  }

  .navbar {
    border-bottom: 5px solid var(--main-color);
  }

  .sidebar {
    .sidebar-header {
      margin-bottom: 0.5rem;
      border-left: 0.8rem solid var(--main-color);
      padding: 0.25rem 1rem;
      box-shadow: rgba(99, 99, 99, 0.2) 0px 2px 8px 0px;
    }

    table {
      width: 100%;
    }
  }

  @media screen and (max-width: 768px) {
    .container.is-fluid {
      padding: 0;

      > .columns {
        margin: 0;

        > .column {
          padding: 0;
        }
      }
    }
  }
</style>
