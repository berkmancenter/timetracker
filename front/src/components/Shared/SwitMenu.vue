<template>
  <div class="switmenu-menu" :class="{ 'switmenu-menu-active': $store.state.shared.sideMenuStatus }">
    <slot></slot>
  </div>
</template>

<script>
  export default {
    name: 'SwitMenuIndex',
    props: {
      buttonSelector: {
        type: String,
        required: true,
      },
      contentSelector: {
        type: String,
        required: true,
      },
      closeOnClick: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    data () {
      return {
        button: null,
        body: null,
      }
    },
    mounted () {
      this.mitt.on('closeSideMenu', () => that.closeMenu())

      this.button = document.querySelector(this.buttonSelector)
      this.content = document.querySelector(this.contentSelector)
      this.body = document.querySelector('body')

      this.toggleBodyClass()

      if (!this.button || !this.contentSelector) {
        return
      }

      this.content.classList.add('switmenu-content')

      this.button.onclick = this.toggleMenu

      const that = this
      document.querySelectorAll('.switmenu-menu a').forEach(function(element) {
        if (that.closeOnClick) {
          element.onclick = function() {
            that.closeMenu()
          }
        }
      })
    },
    methods: {
      toggleMenu() {
        this.$store.dispatch('shared/setSideMenuStatus', !this.$store.state.shared.sideMenuStatus)
        this.toggleBodyClass()
      },
      closeMenu() {
        this.$store.dispatch('shared/setSideMenuStatus', false)
        this.toggleBodyClass()
      },
      toggleBodyClass() {
        if (this.$store.state.shared.sideMenuStatus) {
          this.body.classList.add('switmenu-body-open')
        } else {
          this.body.classList.remove('switmenu-body-open')
        }
      },
    },
  }
</script>

<style lang="scss">
  .switmenu-menu {
    position: fixed;
    padding: 1rem;
    height: 100%;
    width: 25%;
    top: 0;
    left: 0;
    z-index: 7777;
    display: none;
    background-color: #ffffff;

    @media all and (max-width: 1600px) {
      width: 30%;
    }

    @media all and (max-width: 1300px) {
      width: 35%;
    }

    @media all and (max-width: 900px) {
      width: 40%;
    }

    @media all and (max-width: 700px) {
      width: 100%;
    }

    &.switmenu-menu-active {
      display: block;
    }
  }

  .switmenu-body-open {
    overflow: hidden;

    .switmenu-content {
      margin-left: 25%;

      @media all and (max-width: 1600px) {
        margin-left: 30%;
      }

      @media all and (max-width: 1300px) {
        margin-left: 35%;
      }

      @media all and (max-width: 900px) {
        margin-left: 40%;
      }

      @media all and (max-width: 700px) {
        margin-left: 100%;
      }
    }

    .switmenu-section-header {
      margin-bottom: 0.5rem;
      border-bottom: 0.2rem solid var(--main-color);
      padding: 0.25rem 1rem;
      background-color: #ffffff;
      box-shadow: rgba(99, 99, 99, 0.2) 0px 2px 8px 0px;
    }

    .switmenu-section-content {
      padding: 0 0.5rem;

      table {
        width: 100%;
      }
    }
  }
</style>
