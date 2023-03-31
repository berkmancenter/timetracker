<template>
  <div>
    <nav class="navbar" role="navigation" aria-label="main navigation">
      <div class="navbar-brand">
        <a class="navbar-item" href="/">
          <h3 class="logo is-size-3">T <img :src="logoImg" /> TRACK</h3>
        </a>
      </div>

      <div class="navbar-menu" id="top-navbar-menu">
        <div class="navbar-start">
          <a class="navbar-item" v-for="topMenuItem in topMenuItems" :href="`${apiUrl}/${topMenuItem.path}`">{{ topMenuItem.label }}</a>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <div>
              You are logged in as
              <div class="username">{{ $store.state.tracker.user.username }}</div>
            </div>
          </div>
        </div>
      </div>
    </nav>

    <div class="container is-fluid">
      <div class="columns is-desktop">
        <div class="column sidebar is-full-mobile is-full-tablet is-one-third-desktop is-one-quarter-widescreen">
          <div class="box">
            <month-select></month-select>
            <daily-totals v-if="$store.state.tracker.selectedMonth !== 'all'"></daily-totals>
            <popular></popular>
          </div>
        </div>

        <div class="column is-full-mobile is-full-tablet is-two-thirds-desktop is-three-quarters-widescreen">
          <div class="box">
              <div class="content">
                <entry-form></entry-form>
                <entries></entries>
              </div>
          </div>
        </div>
      </div>
    </div>

    <footer id="footer">© 2022 Timetracker</footer>
  </div>
</template>

<script>
  import logoImg from '@/images/time.svg'
  import DailyTotals from '@/components/Tracker/DailyTotals.vue'
  import MonthSelect from '@/components/Tracker/MonthSelect.vue'
  import Popular from '@/components/Tracker/Popular.vue'
  import EntryForm from './EntryForm.vue'
  import Entries from './Entries.vue'

  export default {
    name: 'TrackerLayout',
    components: {
      DailyTotals,
      MonthSelect,
      Popular,
      EntryForm,
      Entries,
    },
    data() {
      return {
        logoImg: logoImg,
        topMenuItems: [
          {
            label: 'Users',
            path: 'users',
          },
          {
            label: 'Periods',
            path: 'periods',
          },
          {
            label: 'View other timesheets',
            path: 'users/view_other_timesheets',
          },
        ],
        apiUrl: import.meta.env.VITE_API_URL,
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      async initialDataLoad() {
        const months = await this.$store.dispatch('tracker/fetchMonths')

        this.$store.dispatch('tracker/setMonths', months)
        this.$store.dispatch('tracker/reloadViewData', ['popular', 'entries', 'user', 'dailyTotals'])
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
</style>
