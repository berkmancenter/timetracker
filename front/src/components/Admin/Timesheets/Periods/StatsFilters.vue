<template>
  <Modal
    :modelValue="modelValue"
    @update:modelValue="$emit('update:modelValue', $event)"
    title="Statistics filters"
    confirmButtonTitle="Apply filters"
    @confirm="applyFilters"
    @cancel="$emit('update:modelValue', false)"
  >
    <div class="timetracker-period-stats-filter-form">
      <!-- Identifier Filter -->
      <div class="mt-2">
        <label class="label">Identifier</label>
        <input
          class="input"
          type="text"
          v-model="filterValues.identifier"
          placeholder="Search by identifier"
        />
      </div>

      <!-- Hours Range Filter -->
      <div class="mt-2">
        <label class="label">Hours</label>
        <div class="columns">
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.minHours"
              placeholder="Min"
            />
          </div>
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.maxHours"
              placeholder="Max"
            />
          </div>
        </div>
      </div>

      <!-- Total Hours Range Filter -->
      <div class="mt-2">
        <label class="label">Total hours</label>
        <div class="columns">
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.minTotalHours"
              placeholder="Min"
            />
          </div>
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.maxTotalHours"
              placeholder="Max"
            />
          </div>
        </div>
      </div>

      <!-- Balance Range Filter -->
      <div class="mt-2">
        <label class="label">Balance</label>
        <div class="columns">
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.minBalance"
              placeholder="Min"
            />
          </div>
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.maxBalance"
              placeholder="Max"
            />
          </div>
        </div>
      </div>

      <!-- Balance Percentage Range Filter -->
      <div class="mt-2">
        <label class="label">Balance percentage</label>
        <div class="columns">
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.minBalancePercent"
              placeholder="Min"
            />
          </div>
          <div class="column">
            <input
              class="input"
              type="number"
              v-model="filterValues.maxBalancePercent"
              placeholder="Max"
            />
          </div>
        </div>
      </div>

      <!-- Last Entry Date Range -->
      <div class="mt-2">
        <label class="label">Last entry date (MM/DD/YYYY)</label>
        <div class="columns">
          <div class="column">
            <input
              class="input"
              type="text"
              v-model="filterValues.minLastEntryDate"
              placeholder="From date"
            />
          </div>
          <div class="column">
            <input
              class="input"
              type="text"
              v-model="filterValues.maxLastEntryDate"
              placeholder="To date"
            />
          </div>
        </div>
      </div>

      <!-- Custom Fields Filters -->
      <div 
        v-for="field in customFields"
        :key="field.id"
        class="mt-2"
      >
        <label class="label">{{ field.title }}</label>
        <input
          class="input"
          :type="getInputType(field)"
          v-model="filterValues.customFields[field.id]"
          :placeholder="`Filter by ${field.title}`"
        />
      </div>

      <div class="mt-4">
        <button class="button" @click="resetFilters">Reset Filters</button>
      </div>
    </div>
  </Modal>
</template>

<script>
import Modal from '@/components/Shared/Modal.vue'
// The same identifier as in the stats table, so searching by a shown name works
import { getUserIdentifier } from '@/lib/user.js'

function parseFilterDateToIso(input) {
  if (!input) return null

  const match = String(input).trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/)
  if (!match) return null

  const month = Number(match[1])
  const day = Number(match[2])
  const year = Number(match[3])
  const candidate = new Date(Date.UTC(year, month - 1, day))

  if (
    candidate.getUTCFullYear() !== year ||
    candidate.getUTCMonth() !== month - 1 ||
    candidate.getUTCDate() !== day
  ) {
    return null
  }

  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
}

export default {
  name: 'StatsFilters',
  components: {
    Modal
  },
  props: {
    modelValue: {
      type: Boolean,
      default: false
    },
    customFields: {
      type: Array,
      default: () => []
    },
    periodStats: {
      type: Array,
      default: () => []
    }
  },
  emits: ['update:modelValue', 'filter-applied'],
  data() {
    return {
      filterValues: {
        identifier: '',
        minHours: '',
        maxHours: '',
        minTotalHours: '',
        maxTotalHours: '',
        minBalance: '',
        maxBalance: '',
        minBalancePercent: '',
        maxBalancePercent: '',
        minLastEntryDate: '',
        maxLastEntryDate: '',
        customFields: {},
      }
    }
  },
  watch: {
    customFields: {
      immediate: true,
      handler(fields) {
        fields.forEach(field => {
          if (!(field.id in this.filterValues.customFields)) {
            this.filterValues.customFields[field.id] = ''
          }
        })
      },
    },
  },
  methods: {
    getInputType(field) {
      // Map field input types to HTML input types
      switch (field.input_type) {
        case 'number':
          return 'number'
        default:
          return 'text'
      }
    },
    applyFilters() {
      const minDateIso = parseFilterDateToIso(this.filterValues.minLastEntryDate)
      const maxDateIso = parseFilterDateToIso(this.filterValues.maxLastEntryDate)

      const filteredItems = this.periodStats.filter(item => {
        // Identifier filter
        if (this.filterValues.identifier && !getUserIdentifier(item).toLowerCase().includes(this.filterValues.identifier.toLowerCase())) {
          return false
        }

        // Hours filters
        if (this.filterValues.minHours !== '' && parseFloat(item.credits) < parseFloat(this.filterValues.minHours)) {
          return false
        }
        if (this.filterValues.maxHours !== '' && parseFloat(item.credits) > parseFloat(this.filterValues.maxHours)) {
          return false
        }

        // Total hours filters
        if (this.filterValues.minTotalHours !== '' && parseFloat(item.total_hours) < parseFloat(this.filterValues.minTotalHours)) {
          return false
        }
        if (this.filterValues.maxTotalHours !== '' && parseFloat(item.total_hours) > parseFloat(this.filterValues.maxTotalHours)) {
          return false
        }

        // Balance filters
        if (this.filterValues.minBalance !== '' && parseFloat(item.balance) < parseFloat(this.filterValues.minBalance)) {
          return false
        }
        if (this.filterValues.maxBalance !== '' && parseFloat(item.balance) > parseFloat(this.filterValues.maxBalance)) {
          return false
        }

        // Balance percentage filters
        if (this.filterValues.minBalancePercent !== '' && parseFloat(item.balance_percent) < parseFloat(this.filterValues.minBalancePercent)) {
          return false
        }
        if (this.filterValues.maxBalancePercent !== '' && parseFloat(item.balance_percent) > parseFloat(this.filterValues.maxBalancePercent)) {
          return false
        }

        // Last entry date filters (compare YYYY-MM-DD strings to avoid timezone drift)
        if (minDateIso || maxDateIso) {
          if (!item.last_entry_date) {
            return false
          }
          if (minDateIso && item.last_entry_date < minDateIso) {
            return false
          }
          if (maxDateIso && item.last_entry_date > maxDateIso) {
            return false
          }
        }

        // Custom fields filters
        for (const fieldId in this.filterValues.customFields) {
          const filterValue = this.filterValues.customFields[fieldId]
          if (filterValue !== '' && filterValue !== null && filterValue !== undefined) {
            const fieldKey = `custom_field_${fieldId}`
            const itemValue = item[fieldKey] || ''
            
            if (typeof itemValue === 'number') {
              if (parseFloat(itemValue) !== parseFloat(filterValue)) return false
            } else if (!String(itemValue).toLowerCase().includes(String(filterValue).toLowerCase())) {
              return false
            }
          }
        }

        return true
      })

      this.$emit('filter-applied', filteredItems)
      this.$emit('update:modelValue', false)
    },
    resetFilters() {
      // Reset all filter values
      this.filterValues = {
        identifier: '',
        minHours: '',
        maxHours: '',
        minTotalHours: '',
        maxTotalHours: '',
        minBalance: '',
        maxBalance: '',
        minBalancePercent: '',
        maxBalancePercent: '',
        minLastEntryDate: '',
        maxLastEntryDate: '',
        customFields: {}
      }

      // Re-initialize custom fields
      this.customFields.forEach(field => {
        this.filterValues.customFields[field.id] = ''
      })
    },
  }
}
</script>

<style lang="scss"></style>
