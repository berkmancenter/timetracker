<template>
  <div>
    <swit-menu
      button-selector=".side-menu-toggler"
      content-selector=".timetracker-content"
      :close-on-click="false"
    >
      <router-view name="Sidebar"></router-view>
    </swit-menu>

    <nav class="top-nav">
      <div class="top-nav-brand no-select">
        <a class="side-menu-toggler hvr-grow">
          <svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><defs></defs><title/><g data-name="70-Menu" id="_70-Menu"><rect class="cls-1" height="6" width="6" x="1" y="1"/><rect class="cls-1" height="6" width="6" x="25" y="1"/><rect class="cls-1" height="6" width="6" x="13" y="1"/><rect class="cls-1" height="6" width="6" x="1" y="13"/><rect class="cls-1" height="6" width="6" x="1" y="25"/><rect class="cls-1" height="6" width="6" x="25" y="25"/><rect class="cls-1" height="6" width="6" x="25" y="13"/><rect class="cls-1" height="6" width="6" x="13" y="13"/><rect class="cls-1" height="6" width="6" x="13" y="25"/></g></svg>
        </a>

        <router-link :to="'/'" class="top-nav-name-link ml-4">
          <h3 class="logo is-size-3">T <img :src="logoImg" /> TRACK</h3>
        </router-link>
      </div>

      <div class="top-nav-end">
        <spinner />

        <div class="top-nav-user-menu">
          <VDropdown>
            <div class="top-nav-user-menu-toggler no-select">
              <svg enable-background="new 0 0 48 48" height="48px" id="Layer_1" version="1.1" viewBox="0 0 48 48" width="48px" xml:space="preserve" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><path clip-rule="evenodd" d="M24,45C12.402,45,3,35.598,3,24S12.402,3,24,3s21,9.402,21,21S35.598,45,24,45z   M35.633,39c-0.157-0.231-0.355-0.518-0.514-0.742c-0.277-0.394-0.554-0.788-0.802-1.178C34.305,37.062,32.935,35.224,28,35  c-1.717,0-2.965-1.288-2.968-3.066L25,31c0-0.135-0.016,0.148,0,0v-1l1-1c0.731-0.339,1.66-0.909,2.395-1.464l0.135-0.093  C29.111,27.074,29.923,26.297,30,26l0.036-0.381C30.409,23.696,31,20.198,31,19c0-4.71-2.29-7-7-7c-4.775,0-7,2.224-7,7  c0,1.23,0.591,4.711,0.963,6.616l0.035,0.352c0.063,0.313,0.799,1.054,1.449,1.462l0.098,0.062C20.333,28.043,21.275,28.657,22,29  l1,1v1c0.014,0.138,0-0.146,0,0l-0.033,0.934c0,1.775-1.246,3.064-2.883,3.064c-0.001,0-0.002,0-0.003,0  c-4.956,0.201-6.393,2.077-6.395,2.077c-0.252,0.396-0.528,0.789-0.807,1.184c-0.157,0.224-0.355,0.51-0.513,0.741  c3.217,2.498,7.245,4,11.633,4S32.416,41.498,35.633,39z M24,5C13.507,5,5,13.507,5,24c0,5.386,2.25,10.237,5.85,13.694  C11.232,37.129,11.64,36.565,12,36c0,0,1.67-2.743,8-3c0.645,0,0.967-0.422,0.967-1.066h0.001C20.967,31.413,20.967,31,20.967,31  c0-0.13-0.021-0.247-0.027-0.373c-0.724-0.342-1.564-0.814-2.539-1.494c0,0-2.4-1.476-2.4-3.133c0,0-1-5.116-1-7  c0-4.644,1.986-9,9-9c6.92,0,9,4.356,9,9c0,1.838-1,7-1,7c0,1.611-2.4,3.133-2.4,3.133c-0.955,0.721-1.801,1.202-2.543,1.546  c-0.005,0.109-0.023,0.209-0.023,0.321c0,0-0.001,0.413-0.001,0.934h0.001C27.033,32.578,27.355,33,28,33c6.424,0.288,8,3,8,3  c0.36,0.565,0.767,1.129,1.149,1.694C40.749,34.237,43,29.386,43,24C43,13.507,34.493,5,24,5z" fill-rule="evenodd"/></svg>
            </div>

            <template #popper>
              <div class="dropdown-item">
                You are logged in as
                <div>{{ $store.state.shared.user.username }}</div>
              </div>
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
</template>

<script>
  import logoImg from '@/images/time.svg'
  import SwitMenu from '@/components/Shared/SwitMenu.vue'
  import Spinner from '@/components/Shared/Spinner.vue'

  export default {
    name: 'DefaultLayout',
    components: {
      SwitMenu,
      Spinner,
    },
    data() {
      return {
        logoImg: logoImg,
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
  .top-nav {
    height: 4.5rem;
    border-bottom: 5px solid var(--main-color);
    display: flex;
    padding: 0.5rem 1rem;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    z-index: 2;
    background-color: #ffffff;

    .top-nav-brand {
      display: flex;
      align-items: center;

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
        cursor: pointer;
      }

      svg {
        height: 3rem;
        width: 3rem;

        path {
          fill: var(--main-color);
        }
      }
    }

    .top-nav-end {
      margin-left: auto;
      display: flex;
      align-items: center;
    }
  }

  .side-menu-toggler {
    padding: .5rem;
    height: 3rem;
    width: 3rem;
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

    svg .cls-1 {
      fill: none;
      stroke: var(--main-color);
      stroke-linejoin: round;
      stroke-width: 2px;
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
</style>
