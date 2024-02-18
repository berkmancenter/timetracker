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
        <FormField label="Project" accessKey="p">
          <input class="input ui-autocomplete-input" ref="projectInput" type="text" v-model="formValue['project']" @input="changeFormValue('project', $event.target.value)" name="time_entry[project]" id="time_entry_project" autocomplete="off" accesskey="p" />
        </FormField>

        <FormField label="Category" accessKey="c">
          <input class="input ui-autocomplete-input" ref="categoryInput" type="text" v-model="formValue['category']" @input="changeFormValue('category', $event.target.value)" name="time_entry[category]" id="time_entry_category" autocomplete="off" accesskey="c" />
        </FormField>

        <FormField label="Description" accessKey="r">
          <textarea class="textarea" v-model="formValue['description']" name="time_entry[description]" @input="changeFormValue('description', $event.target.value)" id="time_entry_description" accesskey="r"></textarea>
        </FormField>

        <FormField label="Time spent" accessKey="t" :required="true">
          <input class="input" type="number" step="0.25" v-model="formValue['decimal_time']" @input="changeFormValue('decimal_time', $event.target.value)" name="time_entry[decimal_time]" id="time_entry_decimal_time" autocomplete="off" accesskey="t" required />
        </FormField>

        <FormField label="Date" accessKey="a" :required="true">
          <date-picker v-model:value="formValue['entry_date']" format="MMMM D, Y" type="date" value-type="format" input-class="input" :clearable="false" :input-attr="{ accesskey: 'a', required: true }" name="time_entry[entry_date]"></date-picker>
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

        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'dailyTotals', 'totals'])

        this.$store.dispatch('tracker/clearEntryForm')
        this.working = false
        this.mitt.emit('spinnerStop')

        this.visible = false
      },
      changeFormValue(field, value) {
        this.$store.commit('tracker/setFormField', {
          field: field,
          value: value,
        })
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
          preventSubmit: true,
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
          }
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
      }
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
