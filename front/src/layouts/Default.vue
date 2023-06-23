<template>
  <div>
    <nav class="navbar" role="navigation" aria-label="main navigation">
      <div class="navbar-brand">
        <router-link :to="'/'" class="navbar-item">
          <h3 class="logo is-size-3">T <img :src="logoImg" /> TRACK</h3>
        </router-link>
      </div>

      <div class="navbar-menu" id="top-navbar-menu">
        <div class="navbar-start" v-if="$store.state.shared.user.is_admin">
          <router-link to="/admin/users" class="navbar-item">Users</router-link>
          <a class="navbar-item" v-for="topMenuItem in topMenuItems" :href="`${apiUrl}/${topMenuItem.path}`">{{ topMenuItem.label }}</a>
        </div>

        <div class="navbar-end">
          <div class="navbar-item">
            <div>
              You are logged in as
              <div class="username">{{ $store.state.shared.user.username }}</div>
            </div>
          </div>
        </div>
      </div>
    </nav>

    <div class="container is-fluid">
      <div class="columns is-desktop">
        <div class="column sidebar is-full-mobile is-full-tablet is-one-third-desktop is-one-quarter-widescreen">
          <div class="box">
          </div>
        </div>

        <div class="column is-full-mobile is-full-tablet is-two-thirds-desktop is-three-quarters-widescreen">
          <div class="box">
              <div class="content">
                <router-view :key="$route.fullPath" />
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

  export default {
    name: 'DefaultLayout',
    components: {},
    data() {
      return {
        logoImg: logoImg,
        topMenuItems: [
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
        const user = await this.$store.dispatch('shared/fetchUser')

        this.$store.dispatch('shared/setUser', user)
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
