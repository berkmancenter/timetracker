<template>
  <Breadcrumbs :crumbs="breadcrumbs" />

  <div class="content admin-periods-credits">
    <h4 class="is-size-4">Hours</h4>

    <div class="admin-periods-credits-info mb-2">
      for
      <span class="tag is-black is-medium">{{ $store.state.admin.periodCredits?.period?.name }}</span>
      from
      <span class="tag is-black is-medium">{{ $store.state.admin.periodCredits?.period?.from }}</span>
      to
      <span class="tag is-black is-medium">{{ $store.state.admin.periodCredits?.period?.to }}</span>
    </div>

    <div class="mb-4">
      <ActionButton
        class="mr-2"
        :icon="saveSelectedIcon"
        buttonText="Set hours selected"
        @click="saveCreditsSelectedModalOpen()"
        :disabled="saveSelectedDisabled"
      />

      <ActionButton
        :icon="saveAllIcon"
        buttonText="Save all visible"
        @click="saveCreditsAll"
        :disabled="saveAllDisabled"
      />
    </div>

    <SuperAdminFilter :users="$store.state.admin.periodCredits?.credits" @change="superAdminFilterChanged" />

    <AdminTable :tableClasses="['admin-periods-credits-table']">
      <thead>
        <tr class="no-select">
          <th data-sort-method="none" class="no-sort">
            <input type="checkbox" ref="toggleAllCheckbox" @click="toggleAll()">
          </th>
          <th>Identifier</th>
          <th data-sort-method="none" class="no-sort">Hours</th>
          <th v-for="field in customFields" :key="field.id" data-sort-method="none" class="no-sort">
            {{ field.title }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="periodCredit in filteredItems" :key="periodCredit.user_id">
          <td class="admin-table-selector">
            <input type="checkbox" v-model="periodCredit.selected">
          </td>
          <td class="no-break">{{ getUserIdentifier(periodCredit) }}</td>
          <td class="no-break admin-periods-credits-table-hours">
            <input class="input" type="number" v-model="periodCredit.credit_amount">
          </td>
          <td v-for="field in customFields" :key="`${periodCredit.user_id}-${field.id}`" class="custom-field-cell">
            <input 
              class="input" 
              :type="getInputType(field)" 
              :value="periodCredit[`custom_field_${field.id}`] || ''"
              @input="updateCustomFieldValue(periodCredit, field, $event.target.value)"
            >
          </td>
        </tr>
        <tr v-if="filteredItems.length === 0">
          <td :colspan="3 + customFields.length">No records found.</td>
        </tr>
      </tbody>
    </AdminTable>
  </div>

  <Modal
    v-model="periodCreditsSelectedSetModalStatus"
    title="Set period hours"
    confirmButtonTitle="Save"
    @confirm="saveCreditsSelected()"
    @cancel="periodCreditsSelectedSetModalStatus = false"
  >
    Input how many hours you want to set to selected users.
    <input type="number" step="1" class="input mt-2" v-model="creditHours">
  </Modal>
</template>

<script>
  import AdminTable from '@/components/Admin/AdminTable.vue'
  import SuperAdminFilter from '@/components/Admin/SuperAdminFilter.vue'
  import Modal from '@/components/Shared/Modal.vue'
  import ActionButton from '@/components/Shared/ActionButton.vue'
  import saveAllIcon from '@/images/all_main.svg'
  import saveSelectedIcon from '@/images/selected_main.svg'
  import Breadcrumbs from '@/components/Shared/Breadcrumbs.vue'

  import { getUserIdentifier } from '@/lib/user.js'

  export default {
    name: 'AdminPeriodsCredits',
    components: {
      AdminTable,
      SuperAdminFilter,
      Modal,
      ActionButton,
      Breadcrumbs,
    },
    data() {
      return {
        filteredItems: [],
        periodCreditsSelectedSetModalStatus: false,
        creditHours: 0.0,
        saveAllIcon,
        saveSelectedIcon,
        saveSelectedDisabled: false,
        saveAllDisabled: false,
        getUserIdentifier,
      }
    },
    computed: {
      breadcrumbs() {
        let breadcrumbs = []

        breadcrumbs.push({
          text: 'Timesheets',
          link: '/admin/timesheets',
        })

        breadcrumbs.push({
          text: this.$store.state.admin?.timesheet?.name,
        })

        breadcrumbs.push({
          text: 'Periods',
          link: `/admin/timesheets/${this.$store.state.admin?.timesheet?.id}/periods`,
        })

        breadcrumbs.push({
          text: this.$store.state.admin.periodCredits?.period?.name,
        })

        breadcrumbs.push({
          text: 'Set hours',
        })

        return breadcrumbs
      },
      customFields() {
        return this.$store.state.admin.periodCredits?.period?.custom_fields || []
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
        this.mitt.emit('spinnerStart')

        const periodCredits = await this.$store.dispatch('admin/fetchPeriodCredits', {
          periodId: this.$route.params.id,
          timesheetId: this.$route.params.timesheet_id,
        })
        const timesheet = await this.$store.dispatch('admin/fetchTimesheet', this.$route.params.timesheet_id)
        this.$store.dispatch('admin/setTimesheet', timesheet)
        this.$store.dispatch('admin/setPeriodCredits', periodCredits)

        // Initialize custom field properties on credits objects
        this.initializeCustomFieldProperties()

        this.mitt.emit('spinnerStop')
      },
      initializeCustomFieldProperties() {
        const credits = this.$store.state.admin.periodCredits?.credits || []
        const fields = this.$store.state.admin.periodCredits?.period?.custom_fields || []
        
        credits.forEach(credit => {
          fields.forEach(field => {
            // Initialize custom field property if not exists
            if (!credit.hasOwnProperty(`custom_field_${field.id}`)) {
              credit[`custom_field_${field.id}`] = ''
            }
          })
        })
      },
      getInputType(field) {
        // Map field input types to HTML input types
        switch (field.input_type) {
          case 'number':
            return 'number'
          default:
            return 'text'
        }
      },
      updateCustomFieldValue(credit, field, value) {
        credit[`custom_field_${field.id}`] = value
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
        this.mitt.emit('spinnerStart')
        this.saveAllDisabled = true

        const response = await this.$store.dispatch('admin/savePeriodCredits', {
          periodId: this.$route.params.id,
          timesheetId: this.$route.params.timesheet_id,
          credits: this.filteredItems,
        })

        if (response?.ok) {
          this.awn.success('Hours have been saved.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
        this.saveAllDisabled = false
      },
      saveCreditsSelectedModalOpen() {
        const selected = this.filteredItems.filter(credit => credit.selected)

        if (selected.length === 0) {
          this.awn.warning('No records selected.')
          return
        }

        this.periodCreditsSelectedSetModalStatus = true
      },
      async saveCreditsSelected() {
        const selected = this.filteredItems.filter(credit => credit.selected)

        this.mitt.emit('spinnerStart')
        this.saveSelectedDisabled = true

        selected.forEach(credit => {
          credit.credit_amount = this.creditHours
        })

        const response = await this.$store.dispatch('admin/savePeriodCredits', {
          periodId: this.$route.params.id,
          timesheetId: this.$route.params.timesheet_id,
          credits: selected,
        })

        if (response?.ok) {
          this.awn.success('Hours have been saved.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
        this.saveSelectedDisabled = false
        this.periodCreditsSelectedSetModalStatus = false
      },
      superAdminFilterChanged(users) {
        this.filteredItems = users
      },
    },
  }
</script>

<style lang="scss">
  .admin-periods-credits {
    &-table-hours {
      width: 8rem;
    }

    &-info {
      span {
        margin-bottom: 1rem;
      }
    }
  }
</style>
