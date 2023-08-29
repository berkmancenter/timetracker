<template>
  <div class="switmenu-menu" :class="{ 'switmenu-menu-active': $store.state.shared.layout.sideMenuStatus }">
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
      this.html = document.querySelector('html')

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
        this.$store.dispatch('shared/setSideMenuStatus', !this.$store.state.shared.layout.sideMenuStatus)
        this.toggleBodyClass()
      },
      closeMenu() {
        this.$store.dispatch('shared/setSideMenuStatus', false)
        this.toggleBodyClass()
      },
      toggleBodyClass() {
        if (this.$store.state.shared.layout.sideMenuStatus) {
          this.html.classList.add('switmenu-html-open')
        } else {
          this.html.classList.remove('switmenu-html-open')
        }
      },
    },
  }
</script>

<style lang="scss">
  html {
    background-color: var(--super-light-color);
  }

  .switmenu-menu {
    position: fixed;
    overflow-y: auto;
    overflow-x: hidden;
    height: 100%;
    width: 25%;
    top: 3.5rem;
    left: 0;
    z-index: 1;
    display: none;
    background-color: #ffffff;
    padding-top: 1.5rem;
    padding-bottom: 6rem;
    padding-right: 0.5rem;
    border-right: 2px solid #F5F5F6;
    background-color: var(--super-light-color);

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

  .switmenu-html-open {
    @media all and (max-width: 700px) {
      overflow: hidden;
    }

    .switmenu-content {
      margin-left: calc(25% + 1rem);

      @media all and (max-width: 1600px) {
        margin-left: calc(30% + 1rem);
      }

      @media all and (max-width: 1300px) {
        margin-left: calc(35% + 1rem);
      }

      @media all and (max-width: 900px) {
        margin-left: calc(40% + 1rem);
      }
    }

    .switmenu-section-header {
      margin-bottom: 0.5rem;
      padding: 0.25rem 1rem;
      background-color: #ffffff;
      border-radius: 0 0.8rem 0.8rem 0;
      box-shadow: rgba(17, 18, 54, 0.16) 0px 1px 4px 0px;
      user-select: none;
    }

    .switmenu-section-content {
      padding: 0 0.5rem;

      table {
        width: 100%;
      }
    }
  }

  .switmenu-content {
    background-color: #ffffff;
    margin-top: 5.5rem;
    margin-left: 1rem;
    margin-right: 1rem;
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
</style>
