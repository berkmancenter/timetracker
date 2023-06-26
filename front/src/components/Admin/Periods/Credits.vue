<template>
  <div class="content admin-periods-credits">
    <h1 class="is-size-1">Credits</h1>

    <h3 class="is-size-4">
      for
      <span class="tag is-black is-large">{{ $store.state.admin.periodCredits?.period?.name }}</span>
      from
      <span class="tag is-black is-large">{{ $store.state.admin.periodCredits?.period?.from }}</span>
      to
      <span class="tag is-black is-large">{{ $store.state.admin.periodCredits?.period?.to }}</span>
    </h3>

    <div class="mb-4">
      <a class="button is-info mr-2" @click="saveCreditsSelected()">Set credits selected</a>
      <a class="button is-info" @click="saveCreditsAll()">Save all</a>
    </div>

    <admin-table :tableClasses="['admin-periods-credits-table']">
      <thead>
        <tr class="no-select">
          <th data-sort-method="none" class="no-sort">
            <input type="checkbox" ref="toggleAllCheckbox" @click="toggleAll()">
          </th>
          <th>Username</th>
          <th>Email</th>
          <th data-sort-method="none" class="no-sort">Credits</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="periodCredit in $store.state.admin.periodCredits?.credits">
          <td>
            <input type="checkbox" v-model="periodCredit.selected">
          </td>
          <td>{{ cleanUsername(periodCredit.user.username) }}</td>
          <td>{{ periodCredit.user.email }}</td>
          <td>
            <input class="input" type="number" v-model="periodCredit.amount">
          </td>
        </tr>
        <tr v-if="$store.state.admin.periodCredits?.credits?.length === 0">
          <td colspan="7">No records found.</td>
        </tr>
      </tbody>
    </admin-table>

    <div ref="periodCreditsSelectedSetTemplate" class="is-hidden">
      <div class="content">
        <p>Input how many credits you want to set to selected users.</p>
        <input type="number" step="1" class="input periods-credits-selected-set-input" value="0.0">
      </div>
    </div>
  </div>
</template>

<script>
  import cleanUsername from '@/lib/clean-username'
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import Swal from 'sweetalert2'

  export default {
    name: 'AdminPeriodsCredits',
    components: {
      AdminTable,
    },
    data() {
      return {
        cleanUsername: cleanUsername,
      }
    },
    created() {
      this.initialDataLoad()
    },
    methods: {
      initialDataLoad() {
        this.loadCredits()
      },
      async loadCredits() {
        const periodCredits = await this.$store.dispatch('admin/fetchPeriodCredits', this.$route.params.id)

        this.$store.dispatch('admin/setPeriodCredits', periodCredits)
      },
      toggleAll() {
        const newStatus = this.$refs.toggleAllCheckbox.checked

        this.$store.state.admin.periodCredits.credits
          .map((credit) => {
            credit.selected = newStatus

            return credit
          })
      },
      async saveCreditsAll() {
        const response = await this.$store.dispatch('admin/savePeriodCredits', {
          id: this.$store.state.admin.periodCredits.period.id,
          credits: this.$store.state.admin.periodCredits.credits,
        })

        if (response?.ok) {
          this.awn.success('Credits have been saved.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }
      },
      async saveCreditsSelected() {
        const that = this
        const inputSelector = '.swal2-html-container .periods-credits-selected-set-input'
        const selected = this.$store.state.admin.periodCredits.credits
          .filter(credit => credit.selected)

        if (selected.length === 0) {
          this.awn.warning('No records selected.')

          return
        }

        Swal.fire({
          icon: 'question',
          showCancelButton: true,
          confirmButtonText: 'Set',
          confirmButtonColor: this.colors.main,
          html: this.$refs.periodCreditsSelectedSetTemplate.innerHTML,
          didOpen: () => document.querySelector(inputSelector).focus(),
        }).then(async (result) => {
          if (result.isConfirmed) {
            const newCreditValue = document.querySelector(inputSelector).value

            selected
              .map(credit => credit.amount = newCreditValue)

              const response = await this.$store.dispatch('admin/savePeriodCredits', {
                id: this.$store.state.admin.periodCredits.period.id,
                credits: selected,
              })

              if (response?.ok) {
                this.awn.success('Credits have been saved.')
              } else {
                this.awn.warning('Something went wrong, try again.')
              }
          }
        })
      },
    },
  }
</script>

<style lang="scss">
  @import '@/assets/scss/admin-table.scss';
</style>
