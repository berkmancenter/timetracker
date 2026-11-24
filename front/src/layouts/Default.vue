<template>
  <div
    class="app-shell"
    :class="[
      `app-shell--sidebar-${sidebarMode}`,
      { 'app-shell--sidebar-open': isSidebarOpen },
    ]"
  >
    <nav class="top-nav">
      <div class="top-nav-brand no-select">
        <button
          v-if="hasSidebar"
          type="button"
          class="side-menu-toggler top-nav-button"
          :aria-expanded="String(isSidebarOpen)"
          aria-label="Toggle sidebar"
          @click="toggleSideMenu"
        >
          <Icon :src="menuIcon" />
        </button>

        <div class="top-nav-brand-name-link ml-2">
          <h3 class="logo is-size-3">T <img :src="logoImg" /> TRACKer</h3>
        </div>

        <router-link
          :to="{ name: 'tracker.index' }"
          @click="reloadPath"
          class="ml-4 top-nav-button top-nav-button-menu"
          :class="{ 'top-nav-button-menu-active': isMenuItemActive('tracker') }"
        >
          Time entries
        </router-link>

        <router-link
          :to="{ name: 'timesheets.index' }"
          class="ml-2 top-nav-button top-nav-button-menu"
          :class="{ 'top-nav-button-menu-active': isMenuItemActive('timesheets') }"
        >
          Timesheets
        </router-link>
      </div>

      <div class="top-nav-end">
        <spinner />

        <div class="top-nav-help top-nav-button">
          <a href="https://berkman-klein-center.gitbook.io/timetracker" target="_blank">
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

    <div class="app-body">
      <aside
        v-if="hasSidebar"
        class="app-sidebar"
        :aria-hidden="String(!isSidebarOpen)"
      >
        <router-view name="Sidebar" />
      </aside>

      <main class="app-main">
        <div class="timetracker-content content">
          <div class="container is-fluid mt-4">
            <router-view />
          </div>

          <footer id="footer">© 2013 - {{ new Date().getFullYear() }} Timetracker</footer>
        </div>
      </main>
    </div>
  </div>

  <ModalsContainer />
  <ServerNotice />
</template>

<script>
  import logoImg from '@/images/time.svg'
  import helpIcon from '@/images/help.svg'
  import userIcon from '@/images/user.svg'
  import menuIcon from '@/images/menu.svg'
  import Spinner from '@/components/Shared/Spinner.vue'
  import { redirectToSelectedMonth } from '@/router/index'
  import { ModalsContainer } from 'vue-final-modal'
  import Icon from '@/components/Shared/Icon.vue'
  import ServerNotice from '@/components/Shared/ServerNotice.vue'

  export default {
    name: 'DefaultLayout',
    components: {
      Spinner,
      ModalsContainer,
      Icon,
      ServerNotice,
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
    computed: {
      sidebarMode() {
        return this.$route?.meta?.sidebar || 'full'
      },
      hasSidebar() {
        return this.sidebarMode !== 'none'
      },
      isSidebarOpen() {
        return this.hasSidebar && Boolean(this.$store.state.shared.layout.sideMenuStatus)
      },
    },
    created() {
      this.closeSideMenuHandler = () => this.closeSideMenu()
      this.mitt.on('closeSideMenu', this.closeSideMenuHandler)
      this.initialDataLoad()
    },
    beforeUnmount() {
      this.mitt.off('closeSideMenu', this.closeSideMenuHandler)
    },
    methods: {
      async initialDataLoad() {
        const user = await this.$store.dispatch('shared/fetchUser')

        this.$store.dispatch('shared/setUser', user)
      },
      toggleSideMenu() {
        this.$store.dispatch('shared/setSideMenuStatus', !this.$store.state.shared.layout.sideMenuStatus)
      },
      closeSideMenu() {
        this.$store.dispatch('shared/setSideMenuStatus', false)
      },
      reloadPath() {
        this.redirectToSelectedMonth(this.$store)
      },
      async logout() {
        this.mitt.emit('spinnerStart')
        await this.$store.dispatch('shared/logout')
      },
      isMenuItemActive(type) {
        if (this.$route.name === 'tracker.index' && type === 'tracker') {
          return true
        }

        if (this.$route.name === 'timesheets.index' && type === 'timesheets') {
          return true
        }

        if (this.$route.name === 'periods.index' && type === 'periods') {
          return true
        }

        return false
      },
    },
  }
</script>

<style lang="scss">
  html {
    background-color: var(--super-light-color);
    overflow-y: auto;
    overscroll-behavior: none;

    @media all and (max-width: 700px) {
      &:has(.app-shell--sidebar-open) {
        overflow: hidden;
      }
    }
  }

  body, button, input, optgroup, select, textarea {
    color: #000000;
    font-family: var(--main-font-family);
  }

  .app-shell {
    --top-nav-offset: calc(4rem + 5px);
    --sidebar-width: 25%;

    @media all and (max-width: 1600px) { --sidebar-width: 30%; }
    @media all and (max-width: 1300px) { --sidebar-width: 35%; }
    @media all and (max-width: 900px) { --sidebar-width: 40%; }
    @media all and (max-width: 700px) { --sidebar-width: 100%; }
  }

  // Top Navigation
  .top-nav {
    height: 4rem;
    border-bottom: 5px solid var(--main-color);
    display: flex;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    z-index: 10001;
    background-color: #ffffff;
    box-sizing: content-box;

    &-brand {
      display: flex;
      align-items: center;
      margin-left: 1rem;

      &-name-link {
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

    &-user-menu {
      &-toggler {
        display: flex;
      }
    }

    &-end {
      margin-left: auto;
      display: flex;
      align-items: center;
      margin-right: 1rem;
    }

    &-button {
      height: 4rem;
      width: 4rem;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      border: 0;
      background: transparent;
      padding: 0;

      img,
      img.tracker-icon {
        height: 3rem;
        width: 3rem;
        max-width: 3rem;
        padding: 0.5rem;
        margin-right: 0;
      }

      &:hover,
      img:hover {
        background-color: var(--greyish-color);
      }

      &-menu {
        height: 2.5rem;
        width: auto;
        display: flex;
        align-items: center;
        padding: 0 0.5rem;
        border-radius: 0.5rem;
        color: #000000;

        @media all and (max-width: 700px) {
          display: none;
        }

        &:hover,
        &-active {
          background-color: var(--greyish-color);
          color: #000000;
        }
      }
    }

    @media all and (max-width: 700px) {
      &-help {
        display: none;
      }
    }
  }

  // Reactive Application Shell (Sidebar + Main)
  .app-body {
    display: flex;
    padding-top: var(--top-nav-offset);
    min-height: 100vh;
  }

  .app-sidebar {
    position: fixed;
    top: var(--top-nav-offset);
    bottom: 0;
    left: 0;
    width: var(--sidebar-width);
    overflow-y: auto;
    overflow-x: hidden;
    z-index: 100;
    background-color: var(--greyish-color);
    padding: 1rem 0.5rem 1rem 0;
    transform: translateX(-100%);
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
    transition: transform 0.4s cubic-bezier(0.19, 1, 0.22, 1),
                opacity 0.3s ease-in-out,
                visibility 0.3s ease-in-out;
    will-change: transform, opacity;

    @media all and (max-width: 700px) {
      z-index: 10000;
    }

    .timetracker-menu {
      ul a {
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
          margin-right: 0.5rem;
        }
      }
    }

    .sidebar-section-header {
      margin-bottom: 0.5rem;
      padding: 0.25rem 1rem;
      background-color: #ffffff;
      border-radius: 0 0.8rem 0.8rem 0;
      box-shadow: rgba(17, 18, 54, 0.16) 0px 1px 4px 0px;
      user-select: none;
      display: flex;
    }

    .sidebar-section-content {
      padding: 0 1rem;

      table {
        width: 100%;
      }
    }
  }

  .app-shell--sidebar-open {
    .app-sidebar {
      transform: translateX(0);
      opacity: 1;
      visibility: visible;
      pointer-events: auto;
      box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);

      .sidebar-section-content {
        animation: slideUp 0.5s ease-out forwards;
      }
    }
  }

  // On desktop, tracker views already show main nav links in the top bar,
  // while admin routes only use the sidebar as a mobile navigation drawer.
  @media all and (min-width: 701px) {
    .app-shell--sidebar-full {
      .app-sidebar .timetracker-menu {
        display: none;
      }

      &.app-shell--sidebar-open .app-main {
        margin-left: var(--sidebar-width);
      }
    }

    .app-shell--sidebar-mobile-only {
      .side-menu-toggler,
      .app-sidebar {
        display: none;
      }
    }
  }

  .app-main {
    flex: 1;
    min-width: 0;
    padding: 1.25rem 1rem 2rem;
    transition: margin-left 0.4s cubic-bezier(0.19, 1, 0.22, 1);

    @media all and (max-width: 700px) {
      padding: 0 0 2rem;
    }
  }

  // Container
  .container.is-fluid {
    padding: 0 1rem;
  }

  // Timetracker Content
  .timetracker-content {
    background-color: #ffffff;
    width: 100%;
    margin: 0;
    border-radius: 1rem;
    padding-top: 0.5rem;
    box-shadow: rgba(17, 18, 54, 0.16) 0px 1px 4px 0px;
    overflow: hidden;

    @media all and (max-width: 700px) {
      border-radius: 0;
    }

    @media all and (min-width: 1300px) {
      max-width: 1200px;
    }
  }

  // Footer
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

  button,
  a.button {
    img.tracker-icon {
      padding: 0;
      margin-right: 0.2rem;
    }

    > * {
      height: 100%;
    }
  }

  h1, h2, h3, h4, h5, h6,
  label {
    user-select: none;
  }

  // Custom Scrollbar
  ::-webkit-scrollbar {
    width: 6px;
  }

  ::-webkit-scrollbar-track {
    -webkit-box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.3);
    border-radius: 10px;
  }

  ::-webkit-scrollbar-thumb {
    border-radius: 10px;
    background: rgb(209, 184, 185);
    -webkit-box-shadow: inset 0 0 6px rgba(0, 0, 0, 0.5);
  }

  @keyframes slideUp {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }
</style>
