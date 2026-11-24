<template>
  <Modal
    v-model="visible"
    title="Time entry data"
    :confirmButtonTitle="submitButtonName"
    :focusOnConfirm="false"
    :working="working"
    @confirm="submitForm()"
    @cancel="visible = false"
  >
    <div class="tracker-entry-form">
      <form
        @submit.prevent="submitForm()"
        ref="entryForm"
      >
        <template
          v-for="field in $store.state.tracker.selectedTimesheet.custom_fields"
          :key="field.id"
        >
          <FormField
            v-if="field.input_type === 'text'"
            :label="field.title"
            :accessKey="field.access_key"
            :id="field.machine_name"
          >
            <input
              class="input ui-autocomplete-input"
              type="text"
              v-model="formValue['fields'][field.machine_name]"
              autocomplete="off"
              :ref="`${field.machine_name}Input`"
              :id="field.machine_name"
              :accessKey="field.access_key"
            />
          </FormField>

          <FormField
            v-if="field.input_type === 'long_text'"
            :label="field.title"
            :accessKey="field.access_key"
            :id="field.machine_name"
            :machineName="field.machine_name"
          >
            <textarea
              class="textarea"
              v-model="formValue['fields'][field.machine_name]"
              :id="field.machine_name"
              :accessKey="field.access_key"
            ></textarea>
          </FormField>
        </template>

        <FormField
          label="Time spent"
          accessKey="t"
          :required="true"
          id="time_entry_decimal_time"
        >
          <input
            class="input"
            type="number"
            min="0.25"
            step="0.25"
            max="99"
            v-model="formValue['decimal_time']"
            @keypress="isNumberKey($event)"
            name="decimal_time"
            id="time_entry_decimal_time"
            autocomplete="off"
            accesskey="t"
            required
          />
        </FormField>

        <FormField
          label="Date"
          accessKey="a"
          :required="true"
          id="time_entry_entry_date"
        >
          <date-picker
            v-model:value="formValue['entry_date']"
            format="MMMM D, Y"
            type="date"
            value-type="format"
            input-class="input"
            :clearable="false"
            :input-attr="{ accesskey: 'a', required: true }"
            name="entry_date"
            id="time_entry_entry_date"
          ></date-picker>
        </FormField>

        <input
          class="tracker-entry-form-submit-button"
          type="submit"
        >
      </form>
    </div>
  </Modal>
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
      }
    },
    created() {
      // Not reactive on purpose, these are only kept to clean up later
      this.autocompletes = []
      this.mittHandlers = {
        addEntry: () => this.openForm(true),
        editEntry: () => this.openForm(),
        cloneEntry: () => this.openForm(),
        popularSelected: () => this.openForm(),
      }
    },
    mounted() {
      this.initEvents()
    },
    beforeUnmount() {
      this.removeEvents()
      this.destroyAutoComplete()
    },
    watch: {
      visible(isVisible) {
        if (!isVisible) {
          this.destroyAutoComplete()
        }
      },
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
      async submitForm() {
        // Enter in the form and the confirm button both submit, so it can come twice
        if (this.working || this.$refs.entryForm.reportValidity() === false) {
          return
        }

        this.working = true
        this.mitt.emit('spinnerStart')

        let saved = false
        try {
          const savedEntry = await this.$store.dispatch('tracker/submitEntryForm')

          if (this.$store.state.tracker.formMode === 'create') {
            this.$store.dispatch('tracker/addEntry', savedEntry)
          } else {
            this.$store.dispatch('tracker/replaceEntry', savedEntry)
          }

          saved = true
        } catch (error) {
          console.error(error)
          this.awn.warning('The time entry could not be saved, try again.')
        }

        if (saved) {
          try {
            if (this.$store.state.tracker.isPeriodView) {
              await this.$store.dispatch('tracker/reloadViewData', ['entries', 'periodTotals', 'totals'])
            } else {
              const months = await this.$store.dispatch('tracker/fetchMonths')

              this.$store.dispatch('tracker/setMonths', months)
              this.$store.dispatch('tracker/setSelectedMonthFromRoute')

              await this.$store.dispatch('tracker/reloadViewData', ['popular', 'periodTotals', 'totals'])
            }
          } catch (error) {
            // The entry is saved, only the refresh failed
            console.error(error)
          }

          this.$store.dispatch('tracker/clearEntryForm')
          this.visible = false
        }

        this.working = false
        this.mitt.emit('spinnerStop')
      },
      // Let only digits and a dot through. The input itself checks min, max and step
      // (so max 2 decimals), it also works when the old value is selected and replaced.
      isNumberKey(event) {
        if (event.ctrlKey || event.metaKey || event.altKey || event.key.length !== 1) {
          return
        }

        if (!/[0-9.]/.test(event.key)) {
          event.preventDefault()
        }
      },
      initAutoComplete() {
        this.destroyAutoComplete()

        this.getTextFields().forEach(field => {
          const input = this.getFieldInput(field)
          if (!input) {
            return
          }

          this.autocompletes.push(autocomplete({
            input,
            preventSubmit: 2, // OnSelect
            showOnFocus: true,
            minLength: 0,
            fetch: async (text, update) => {
              try {
                const items = await this.$store.dispatch('tracker/fetchAutoComplete', {
                  term: text.toLowerCase(),
                  field: field.machine_name,
                })

                update(items.map(item => ({ label: item })))
              } catch (error) {
                update([])
              }
            },
            onSelect: (item) => {
              input.value = item.label
              this.changeFormValue(field.machine_name, item.label)
            },
            render: (item) => {
              if (input.value !== item.label) {
                const div = document.createElement('div')
                // textContent, the values are typed by users and are not HTML
                div.textContent = item.label

                return div
              }
            },
          }))
        })
      },
      // The autocompleter adds listeners to window and document, so it must be removed
      destroyAutoComplete() {
        this.autocompletes.forEach(instance => instance.destroy())
        this.autocompletes = []
      },
      initEvents() {
        Object.entries(this.mittHandlers).forEach(([event, handler]) => this.mitt.on(event, handler))
      },
      removeEvents() {
        Object.entries(this.mittHandlers).forEach(([event, handler]) => this.mitt.off(event, handler))
      },
      async openForm(clearForm = false) {
        if (clearForm) {
          this.$store.dispatch('tracker/clearEntryForm')
        }

        this.visible = true

        await this.waitForLastField()

        // The form could be closed while waiting
        if (!this.visible) {
          return
        }

        this.initAutoComplete()

        // Focus the first field if not on a touch device
        const textFields = this.getTextFields()
        if (textFields.length > 0 && this.isTouchDevice === false) {
          this.getFieldInput(textFields[0])?.focus()
        }
      },
      async waitUntil(condition, timeout = 2000) {
        const startedAt = Date.now()

        while (!condition()) {
          if (Date.now() - startedAt > timeout) {
            throw new Error(`not found after ${timeout} ms`)
          }

          await new Promise(resolve => setTimeout(resolve, 10))
        }
      },
      async waitForLastField() {
        const textFields = this.getTextFields()

        if (textFields.length === 0) {
          return
        }

        const lastField = textFields[textFields.length - 1]

        try {
          await this.waitUntil(() => this.getFieldInput(lastField))
        } catch (error) {
          console.error(`Failed to find last field ${lastField.machine_name}: ${error.message}`)
        }
      },
      // Refs inside v-for are arrays, after the modal is closed the array is empty
      getFieldInput(field) {
        return this.$refs[`${field.machine_name}Input`]?.[0]
      },
      changeFormValue(field, value) {
        this.$store.commit('tracker/setFormField', {
          field: field,
          value: value,
        })
      },
      getTextFields() {
        return this.$store.state.tracker.selectedTimesheet.custom_fields.filter(field => field.input_type === 'text')
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
