<template>
  <!-- Always in the page, so screen readers read what appears in it -->
  <div class="server-notice-area" aria-live="polite">
    <Transition name="server-notice">
      <div v-if="!server.reachable" key="unreachable" class="server-notice server-notice--unreachable">
        <span class="server-notice-dot" />
        Can't reach the server, changes can't be saved until it's back.
      </div>

      <div v-else-if="server.newVersion" key="new-version" class="server-notice">
        <span class="server-notice-dot" />
        A new version of Timetracker is ready, it loads with the next page you open.
        <button type="button" class="button is-small" @click="reload">Reload now</button>
      </div>
    </Transition>
  </div>
</template>

<script>
  export default {
    name: 'ServerNotice',
    computed: {
      server() {
        return this.$store.state.shared.server
      },
    },
    methods: {
      reload() {
        window.location.reload()
      },
    },
  }
</script>

<style lang="scss">
  .server-notice-area {
    position: fixed;
    bottom: 1.5rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 10002;
    width: max-content;
    max-width: calc(100% - 2rem);
    pointer-events: none;
  }

  .server-notice {
    --server-notice-color: var(--main-color);

    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.6rem 0.75rem 0.6rem 1rem;
    border-radius: 0.8rem;
    background-color: #ffffff;
    box-shadow: rgba(17, 18, 54, 0.16) 0px 1px 4px 0px, rgba(17, 18, 54, 0.12) 0px 8px 24px 0px;
    pointer-events: auto;
    line-height: 1.4;

    &--unreachable {
      --server-notice-color: var(--email-color);
    }

    .button {
      flex-shrink: 0;
    }

    &-dot {
      flex-shrink: 0;
      width: 0.6rem;
      height: 0.6rem;
      border-radius: 50%;
      background-color: var(--server-notice-color);
      animation: server-notice-pulse 2s ease-in-out infinite;
    }

    &-enter-active,
    &-leave-active {
      transition: opacity 0.3s ease, transform 0.3s ease;
    }

    &-enter-from,
    &-leave-to {
      opacity: 0;
      transform: translateY(1rem);
    }
  }

  @keyframes server-notice-pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.35; }
  }

  @media (prefers-reduced-motion: reduce) {
    .server-notice-dot {
      animation: none;
    }
  }
</style>
