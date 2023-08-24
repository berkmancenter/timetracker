<template>
  <div class="tracker-workspaces">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">Workspace</h5>

    <div class="switmenu-section-content">
      <div class="select">
        <select v-model="$store.state.tracker.selectedWorkspace">
          <option v-for="workspace in $store.state.tracker.workspaces" :key="workspace.id" :value="workspace">
            {{ workspace.name }}
          </option>
        </select>
      </div>

      <div class="columns">
        <div class="column">
          <button class="button mt-2" @click="changeWorkspace">Change</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  export default {
    name: 'WorkspaceSelect',
    data() {
      return {
        apiUrl: import.meta.env.VITE_API_URL,
      }
    },
    methods: {
      async changeWorkspace() {
        this.mitt.emit('spinnerStart')

        this.$router.push(
          {
            name: 'tracker.index',
            params: {
              workspace: this.$store.state.tracker.selectedWorkspace
            }
          }
        )

        await this.$store.dispatch('tracker/reloadViewData', ['entries', 'dailyTotals', 'months'])

        this.mitt.emit('spinnerStop')
      },
    },
  };
</script>

<style scoped lang="scss">
  select,
  .select {
    width: 100%;
    text-align: center;
  }

  button {
    width: 100%;
  }

  @media screen and (max-width: 768px) {
    .column:first-child {
      padding-bottom: 0;
    }
    .column:last-child {
      padding-top: 0;
    }
  }
</style>
