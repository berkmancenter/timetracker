<template>
  <div id="tracker-entry-form">
    <form @submit.prevent="submitForm" ref="entryForm">
      <h4 class="is-size-4">Time entry data</h4>

      <FormField label="Category" accessKey="c">
        <input class="input ui-autocomplete-input" ref="categoryInput" type="text" v-model="formValue['category']" @input="changeFormValue('category', $event.target.value)" name="time_entry[category]" id="time_entry_category" autocomplete="off" accesskey="c" />
      </FormField>

      <FormField label="Project" accessKey="p">
        <input class="input ui-autocomplete-input" ref="projectInput" type="text" v-model="formValue['project']" @input="changeFormValue('project', $event.target.value)" name="time_entry[project]" id="time_entry_project" autocomplete="off" accesskey="p" />
      </FormField>

      <FormField label="Description" accessKey="r">
        <textarea class="textarea" v-model="formValue['description']" name="time_entry[description]" @input="changeFormValue('description', $event.target.value)" id="time_entry_description" accesskey="r"></textarea>
      </FormField>

      <FormField label="Time spent" accessKey="t">
        <input class="input" type="number" step="0.25" v-model="formValue['decimal_time']" @input="changeFormValue('decimal_time', $event.target.value)" name="time_entry[decimal_time]" id="time_entry_decimal_time" accesskey="t" required />
      </FormField>

      <FormField label="Date" accessKey="a">
        <date-picker v-model:value="formValue['entry_date']" format="MMMM D, Y" type="date" value-type="format" input-class="input" :clearable="false" :input-attr="{ accesskey: 'a', required: true }" name="time_entry[entry_date]"></date-picker>
      </FormField>

      <FormField label="" accessKey="s">
        <input type="submit" name="commit" :value="submitButtonName" class="button is-success entry-form-submit" accesskey="s" />
      </FormField>
    </form>
  </div>
</template>

<script>
  import calImg from '@/images/cal.svg'
  import FormField from './FormField.vue'
  import Icon from './Icon.vue'
  import autocomplete from 'autocompleter'

  export default {
    name: 'EntryForm',
    components: {
      FormField,
      Icon,
    },
    data() {
      return {
        calImg: calImg,
      }
    },
    mounted() {
      this.initAutoComplete()
      this.initEvents()
    },
    computed: {
      formValue() {
        return this.$store.state.tracker.formEntry
      },
      submitButtonName() {
        if (this.$store.state.tracker.formMode === 'create') {
          return 'Add Entry'
        } else {
          return 'Edit Entry'
        }
      },
    },
    methods: {
      async submitForm(ev) {
        const submitResponse = await this.$store.dispatch('tracker/submitEntryForm')

        if (this.$store.state.tracker.formMode === 'create') {
          this.$store.dispatch('tracker/addEntry', submitResponse.entry)
        } else {
          this.$store.dispatch('tracker/replaceEntry', submitResponse.entry)
          this.$store.dispatch('tracker/setFormMode', 'create')
        }

        const months = await this.$store.dispatch('tracker/fetchMonths')
        this.$store.dispatch('tracker/setMonths', months)

        await this.$store.dispatch('tracker/reloadViewData', ['popular', 'dailyTotals'])

        this.$store.dispatch('tracker/clearEntryForm')
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
        this.mitt.on('editEntry', () => that.focusOnForm())
        this.mitt.on('cloneEntry', () => that.focusOnForm())
        this.mitt.on('popularSelected', () => that.focusOnForm())
      },
      focusOnForm() {
        this.$refs.entryForm.scrollIntoView({behavior: 'smooth'})
      },
    },
  }
</script>

<style lang="scss">
  #tracker-entry-form {
    input.entry-form-submit {
      vertical-align: middle;
      margin-right: 0.5rem;
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
