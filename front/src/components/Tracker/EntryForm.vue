<template>
  <Modal
    v-model="visible"
    title="Time entry data"
    :confirmButtonTitle="submitButtonName"
    :focusOnConfirm="false"
    @confirm="submitForm()"
    @cancel="visible = false"
  >
    <div class="tracker-entry-form">
      <form @submit.prevent="submitForm()" ref="entryForm">
        <template v-for="field in $store.state.tracker.selectedTimesheet.timesheet_fields" :key="field.id">
          <FormField
            :label="field.title"
            :accessKey="field.access_key"
            :id="field.machine_name"
            v-if="field.input_type === 'text'"
          >
            <input
              class="input ui-autocomplete-input"
              type="text"
              v-model="formValue['fields'][field.machine_name]"
              autocomplete="off"
              :ref="`${field.machine_name}Input`"
              :id="field.machine_name"
            />
          </FormField>

          <FormField
            :label="field.title"
            :accessKey="field.access_key"
            v-if="field.input_type === 'long_text'"
            :id="field.machine_name"
            :machineName="field.machine_name"
          >
            <textarea
              class="textarea"
              v-model="formValue['fields'][field.machine_name]"
              :id="field.machine_name"
            ></textarea>
          </FormField>
        </template>

        <FormField label="Time spent" accessKey="t" :required="true" id="time_entry_decimal_time">
          <input class="input" type="number" min="0.25" step="0.25" max="99" v-model="formValue['decimal_time']" @keypress="isNumberKey($event)" name="decimal_time" id="time_entry_decimal_time" autocomplete="off" accesskey="t" required />
        </FormField>

        <FormField label="Date" accessKey="a" :required="true" id="time_entry_entry_date">
          <date-picker v-model:value="formValue['entry_date']" format="MMMM D, Y" type="date" value-type="format" input-class="input" :clearable="false" :input-attr="{ accesskey: 'a', required: true }" name="entry_date" id="time_entry_entry_date"></date-picker>
        </FormField>

        <input class="tracker-entry-form-submit-button" type="submit">
      </form>
    </div>
  </Modal>

  <ActionButton
    class="is-success"
    :icon="addIcon"
    buttonText="Add time entry"
    @click="openForm()"
    :button="true"
  />
</template>

<script>
  import addIcon from '@/images/add_white.svg'
  import FormField from './FormField.vue'
  import Icon from '@/components/Shared/Icon.vue'
  import autocomplete from 'autocompleter'
  import Modal from '@/components/Shared/Modal.vue'
  import ActionButton from '@/components/Shared/ActionButton.vue'

  export default {
    name: 'EntryForm',
    components: {
      FormField,
      Icon,
      Modal,
      ActionButton,
    },
    data() {
      return {
        working: false,
        visible: false,
        addIcon,
        submittingInProcess: false,
      }
    },
    mounted() {
      this.initEvents()
    },
    computed: {
      formValue() {
        return this.$store.state.tracker.formEntry
      },
      submitButtonName() {
        if (this.$store.state.tracker.formMode === 'create') {
          return 'Add entry'
        } else {
          return 'Save changes'
        }
      },
    },
    methods: {
      async submitForm(ev) {
        if (this.$refs.entryForm.reportValidity() === false) {
          return
        }

        this.mitt.emit('modalIsWorking')
        this.mitt.emit('spinnerStart')
        this.working = true

        const submitResponse = await this.$store.dispatch('tracker/submitEntryForm')

        if (this.$store.state.tracker.formMode === 'create') {
          this.$store.dispatch('tracker/addEntry', submitResponse)
        } else {
          this.$store.dispatch('tracker/replaceEntry', submitResponse)
        }

        const months = await this.$store.dispatch('tracker/fetchMonths')

        this.$store.dispatch('tracker/setMonths', months)
        this.$store.dispatch('tracker/setSelectedMonthFromRoute')

        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'periodTotals', 'totals'])

        this.$store.dispatch('tracker/clearEntryForm')
        this.working = false
        this.mitt.emit('spinnerStop')
        this.mitt.emit('modalIsNotWorking')

        this.visible = false
      },
      isNumberKey(event) {
        const charCode = event.which ? event.which : event.keyCode

        if (charCode > 31 && (charCode < 48 || charCode > 57) && !(charCode == 46 || charCode == 8)) {
          return event.preventDefault()
        } else {
          const len = event.target.value.length
          const index = event.target.value.indexOf('.')
          if (index > 0 && charCode == 46) {
            return event.preventDefault()
          }
          if (index > 0) {
            const charAfterdot = (len + 1) - index
            if (charAfterdot > 3) {
              return event.preventDefault()
            }
          }
        }

        return true
      },
      initAutoComplete() {
        const that = this

        this.$store.state.tracker.selectedTimesheet.timesheet_fields.forEach(field => {
          if (field.input_type !== 'text') {
            return
          }

          const fieldRefName = `${field.machine_name}Input`

          autocomplete({
            input: that.$refs[fieldRefName][0],
            preventSubmit: 2, // OnSelect
            showOnFocus: true,
            minLength: 0,
            fetch: async (text, update) => {
              let items = await that.$store.dispatch('tracker/fetchAutoComplete', {
                term: text.toLowerCase(),
                field: field.machine_name,
              })

              items = items.map((item) => {
                return { label: item }
              })

              update(items)
            },
            onSelect: function(item) {
              that.$refs[fieldRefName][0].value = item.label
              that.changeFormValue(field.machine_name, item.label)
            },
            render: function(item) {
              if (that.$refs[fieldRefName][0].value !== item.label) {
                const div = document.createElement('div')
                div.innerHTML = item.label

                return div
              }
            },
          })
        });
      },
      initEvents() {
        const that = this
        this.mitt.on('editEntry', () => that.openForm())
        this.mitt.on('cloneEntry', () => that.openForm())
        this.mitt.on('popularSelected', () => that.openForm())
      },
      async openForm(clearForm = false) {
        if (clearForm) {
          this.$store.dispatch('tracker/clearEntryForm')
        }

        this.visible = true

        await this.waitForLastField()

        this.initAutoComplete()

        // Focus the first field if not on a touch device
        const textFields = this.getTextFields()
        if (textFields.length > 0 && this.isTouchDevice === false) {
          const firstField = textFields[0]

          this.$refs[`${firstField.machine_name}Input`][0].focus()
        }
      },
      async waitUntil(condition) {
        return await new Promise(resolve => {
          const interval = setInterval(() => {
            if (condition()) {
              resolve()
              clearInterval(interval)
            }
          }, 10)
        })
      },
      async waitForLastField() {
        const textFields = this.getTextFields()

        if (textFields.length === 0) {
          console.error('No fields available to process.')
          return
        }

        const lastField = textFields[textFields.length - 1]

        try {
          await this.waitUntil(() => this.$refs[`${lastField.machine_name}Input`])
        } catch (error) {
          console.error(`Failed to find last field ${lastField.machine_name}: ${error.message}`)
        }
      },
      changeFormValue(field, value) {
        this.$store.commit('tracker/setFormField', {
          field: field,
          value: value,
        })
      },
      getTextFields() {
        return this.$store.state.tracker.selectedTimesheet.timesheet_fields.filter(field => field.input_type === 'text')
      },
    },
  }
</script>

<style lang="scss">
  .tracker-entry-form {
    &-submit-button {
      position: absolute;
      left: -9999px;
    }
  }

  .autocomplete {
    font: inherit;

    > div:hover:not(.group),
    > div.selected {
      background-color: var(--greyish-color);
    }
  }
</style>
