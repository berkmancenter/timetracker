<template>
  <div>
    <swit-menu
      button-selector=".side-menu-toggler"
      content-selector=".timetracker-content"
      :close-on-click="false"
      v-if="$store.state.shared.layout.sideMenuEnabled"
    >
      <router-view name="Sidebar"></router-view>
    </swit-menu>

    <nav class="top-nav">
      <div class="top-nav-brand no-select">
        <a class="side-menu-toggler top-nav-button" v-if="$store.state.shared.layout.sideMenuEnabled">
          <Icon :src="menuIcon" />
        </a>

        <router-link :to="'/'" @click="reloadPath" class="top-nav-name-link ml-2">
          <h3 class="logo is-size-3">T <img :src="logoImg" /> TRACKer</h3>
        </router-link>
      </div>

      <div class="top-nav-end">
        <spinner />

        <div class="top-nav-help top-nav-button">
          <a href="https://cyber.harvard.edu/team/timetracker/docs/index.html" target="_blank">
            <Icon :src="helpIcon" />
          </a>
        </div>

        <div class="top-nav-user-menu">
          <VDropdown>
            <div class="top-nav-user-menu-toggler top-nav-button no-select">
              <Icon :src="userIcon" />
            </div>

            <template #popper>
              <div class="dropdown-item">
                You are logged in as
                <div>{{ $store.state.shared.user.username }}</div>
              </div>
              <hr class="dropdown-divider">
              <a class="dropdown-item" @click="logout" v-close-popper>
                Logout
              </a>
            </template>
          </VDropdown>
        </div>
      </div>
    </nav>

    <div class="timetracker-content content">
      <div class="container is-fluid mt-4">
        <router-view />
      </div>

      <footer id="footer">© 2013 - {{ new Date().getFullYear() }} Timetracker</footer>
    </div>
  </div>

  <ModalsContainer />
</template>

<script>
  import logoImg from '@/images/time.svg'
  import helpIcon from '@/images/help.svg'
  import userIcon from '@/images/user.svg'
  import menuIcon from '@/images/menu.svg'
  import SwitMenu from '@/components/Shared/SwitMenu.vue'
  import Spinner from '@/components/Shared/Spinner.vue'
  import { redirectToSelectedMonth } from '@/router/index'
  import { ModalsContainer } from 'vue-final-modal'
  import Icon from '@/components/Shared/Icon.vue'

  export default {
    name: 'DefaultLayout',
    components: {
      SwitMenu,
      Spinner,
      ModalsContainer,
      Icon,
    },
    data() {
      return {
        logoImg: logoImg,
        apiUrl: import.meta.env.VITE_API_URL,
        redirectToSelectedMonth: redirectToSelectedMonth,
        helpIcon,
        userIcon,
        menuIcon,
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      async initialDataLoad() {
        const user = await this.$store.dispatch('shared/fetchUser')

        this.$store.dispatch('shared/setUser', user)
      },
      reloadPath() {
        this.redirectToSelectedMonth(this.$store)
      },
      async logout() {
        this.mitt.emit('spinnerStart')
        await this.$store.dispatch('shared/logout')
      },
    },
  }
</script>

<style lang="scss">
  html {
    overflow-y: auto;
  }

  body, button, input, optgroup, select, textarea {
    color: #000000;
    font-family: var(--main-font-family);
  }

  .top-nav {
    height: 4rem;
    border-bottom: 5px solid var(--main-color);
    display: flex;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    z-index: 2;
    background-color: #ffffff;
    box-sizing: content-box;

    .top-nav-brand {
      display: flex;
      align-items: center;
      margin-left: 1rem;

      .top-nav-name-link {
        color: #ffffff;
        margin: 0 auto;

        > h3 {
          color: var(--main-color);
          overflow: hidden;
          white-space: nowrap;
          text-overflow: ellipsis;
          display: flex;
          align-items: center;

          img {
            width: 2rem;
            height: 2rem;
            margin: 0.4rem;
          }
        }
      }
    }

    .top-nav-user-menu {
      .top-nav-user-menu-toggler {
        display: flex;
      }
    }

    .top-nav-end {
      margin-left: auto;
      display: flex;
      align-items: center;
      margin-right: 1rem;
    }

    .top-nav-button {
      height: 4rem;
      width: 4rem;
      display: block;
      cursor: pointer;

      img {
        height: 3rem;
        width: 3rem;
        padding: 0.5rem;
      }

      &:hover
      img:hover {
        background-color: var(--greyish-color);
      }
    }
  }

  .switmenu-menu {
    ul {
      a {
        display: flex;
        background-color: #ffffff;
        padding: 0.5rem 1rem;
        color: #000000;
        border-bottom: 1px solid #F5F5F6;
        align-items: center;

        &:focus,
        &:active {
          background-color: var(--greyish-color);
        }

        &:hover,
        &.router-link-active {
          background-color: var(--main-color);
          color: #ffffff;
        }

        img {
          width: 1rem;
          height: 1rem;
          margin-right: .5rem;
        }
      }
    }
  }

  .container.is-fluid {
    padding: 0 1rem;
  }

  .side-menu-toggler {
    padding: 0;
    width: 2rem;
    height: 2rem;
    background-color: #ffffff;
  }

  .timetracker-content {
    background-color: #ffffff;
    margin-top: 5.5rem;
    margin-left: 1rem;
    margin-right: 1rem;
    margin-bottom: 2rem;
    border-radius: 1rem;
    padding-top: 0.5rem;
    box-shadow: rgba(17, 18, 54, 0.16) 0px 1px 4px 0px;

    @media all and (max-width: 700px) {
      margin-left: 0;
      margin-right: 0;
      border-radius: 0;
      margin-top: 4rem;
    }
  }

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

  /*
    Custom scrollbar styling
  */
  ::-webkit-scrollbar {
    width: 6px;
  }

  ::-webkit-scrollbar-track {
    -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3);
    -webkit-border-radius: 10px;
    border-radius: 10px;
  }

  ::-webkit-scrollbar-thumb {
    -webkit-border-radius: 10px;
    border-radius: 10px;
    background: rgb(209, 184, 185, 1);
    -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.5);
  }
</style>
