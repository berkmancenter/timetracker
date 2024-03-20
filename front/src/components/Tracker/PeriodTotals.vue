<template>
  <div class="tracker-period-totals" v-if="$store.state.tracker.periodTotals.length > 0">
    <h5 class="has-text-weight-bold is-size-5 mt-2 switmenu-section-header">
      {{ periodName }} Totals
      <VDropdown>
        <Icon :src="arrowDownIcon" />

        <template #popper>
          <a class="dropdown-item" @click="setMode('weeks')" v-close-popper v-show="$store.state.tracker.periodTotalsMode == 'days'">
            Weekly Totals
          </a>
          <a class="dropdown-item" @click="setMode('days')" v-close-popper v-show="$store.state.tracker.periodTotalsMode == 'weeks'">
            Daily Totals
          </a>
        </template>
      </VDropdown>
    </h5>

    <div class="switmenu-section-content">
      <table class="table">
        <tbody>
          <template v-for="(item, index) in $store.state.tracker.periodTotals" :key="index">
            <tr>
              <td>{{ item.date }}</td>
              <td>{{ item.total_hours }}</td>
            </tr>
            <tr v-if="$store.state.shared.user.sudoMode">
              <td colspan="2">{{ item.email }}</td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import arrowDownIcon from '@/images/arrow_down.svg'

  export default {
    name: 'PeriodTotals',
    data() {
      return {
        arrowDownIcon,
      }
    },
    components: {
      Icon,
    },
    computed: {
      periodName() {
        if (this.$store.state.tracker.periodTotalsMode === 'days') {
          return 'Daily'
        } else {
          return 'Weekly'
        }
      }
    },
    methods: {
      setMode(mode) {
        this.$store.dispatch('tracker/setPeriodTotalsMode', mode)
      },
    },
  }
</script>

<style lang="scss">
  .tracker-period-totals {
    td {
      word-break: break-word;
      vertical-align: middle;
    }
  }
</style>
