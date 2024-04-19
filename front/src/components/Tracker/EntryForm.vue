<template>
  <Modal
    v-model="visible"
    title="Time entry data"
    :confirmButtonTitle="submitButtonName"
    :focusOnConfirm="false"
    @confirm="submitForm()"
    @cancel="visible = false"
  >
    <div id="tracker-entry-form">
      <form @submit.prevent="submitForm()" ref="entryForm">
        <FormField label="Project" accessKey="p" id="time_entry_project">
          <input class="input ui-autocomplete-input" ref="projectInput" type="text" v-model="formValue['project']" name="time_entry[project]" id="time_entry_project" autocomplete="off" accesskey="p" />
        </FormField>

        <FormField label="Category" accessKey="c" id="time_entry_category">
          <input class="input ui-autocomplete-input" ref="categoryInput" type="text" v-model="formValue['category']" name="time_entry[category]" id="time_entry_category" autocomplete="off" accesskey="c" />
        </FormField>

        <FormField label="Description" accessKey="r" id="time_entry_description">
          <textarea class="textarea" v-model="formValue['description']" name="time_entry[description]" id="time_entry_description" accesskey="r"></textarea>
        </FormField>

        <FormField label="Time spent" accessKey="t" :required="true" id="time_entry_decimal_time">
          <input class="input" type="number" min="0.25" step="0.25" max="99" v-model="formValue['decimal_time']" @keypress="isNumberKey($event)" name="time_entry[decimal_time]" id="time_entry_decimal_time" autocomplete="off" accesskey="t" required />
        </FormField>

        <FormField label="Date" accessKey="a" :required="true" id="time_entry_entry_date">
          <date-picker v-model:value="formValue['entry_date']" format="MMMM D, Y" type="date" value-type="format" input-class="input" :clearable="false" :input-attr="{ accesskey: 'a', required: true }" name="time_entry[entry_date]" id="time_entry_entry_date"></date-picker>
        </FormField>

        <input class="tracker-entry-form-submit-button" type="submit">
      </form>
    </div>
  </Modal>

  <button class="button is-success mb-2" @click="openForm(true)">
    <Icon :src="addIcon" :interactive="false" />
    Add time entry
  </button>
</template>

<script>
  import addIcon from '@/images/add_white.svg'
  import FormField from './FormField.vue'
  import Icon from '@/components/Shared/Icon.vue'
  import autocomplete from 'autocompleter'
  import Modal from '@/components/Shared/Modal.vue'

  export default {
    name: 'EntryForm',
    components: {
      FormField,
      Icon,
      Modal,
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
          this.$store.dispatch('tracker/addEntry', submitResponse.entry)
        } else {
          this.$store.dispatch('tracker/replaceEntry', submitResponse.entry)
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
        this.initAutoCompleteSingle('category')
        this.initAutoCompleteSingle('project')
      },
      initAutoCompleteSingle(type) {
        const that = this
        const fieldRefName = `${type}Input`

        autocomplete({
          input: this.$refs[fieldRefName],
          preventSubmit: 2, // OnSelect
          showOnFocus: true,
          minLength: 0,
          fetch: async (text, update) => {
            let items = await that.$store.dispatch('tracker/fetchAutoComplete', {
              term: text.toLowerCase(),
              field: type,
            })

            items = items.map((item) => {
              return { label: item }
            })

            update(items)
          },
          onSelect: function(item) {
            that.$refs[fieldRefName].value = item.label
            that.changeFormValue(type, item.label)
          },
          render: function(item) {
            if (that.$refs[fieldRefName].value !== item.label) {
              const div = document.createElement('div')
              div.innerHTML = item.label

              return div
            }
          },
        })
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

        await this.waitUntil(() => {
          return this.$refs.categoryInput
        })

        this.initAutoComplete()

        if (!this.isTouchDevice) {
          this.$refs.projectInput.focus()
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
      changeFormValue(field, value) {
        this.$store.commit('tracker/setFormField', {
          field: field,
          value: value,
        })
      },
    },
  }
</script>

<style lang="scss">
  #tracker-entry-form {
    .tracker-entry-form-submit-button {
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
