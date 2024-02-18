<template>
  <div>
    <h4 class="is-size-4 mt-2">Existing entries</h4>

    <article v-if="$store.state.shared.user.sudoMode" class="message is-warning">
      <div class="message-body">
        <div><strong>You are viewing the timesheets of</strong></div>
        {{ activeUsersString }}
        <div>
          <a class="button is-info mt-2" @click="unSudo()">Show only my timesheets</a>
        </div>
      </div>
    </article>

    <div class="tracker-entries-wrapper">
      <table class="tracker-entries table">
        <thead>
          <tr>
            <th>Project</th>
            <th>Category</th>
            <th>Hours</th>
            <th v-if="$store.state.shared.user.sudoMode">Username</th>
          </tr>
        </thead>
        <template v-for="(entries, date) in entriesByDate">
          <tbody>
            <tr class="tracker-entries-date-row">
              <td colspan="5" class="tracker-entries-date-cell is-size-4" v-if="isNewDay(date)">{{ formatDate(date) }}</td>
            </tr>

            <template v-for="entry in entries" :key="entry.id">
              <tr class="tracker-entries-entry" @mouseenter="enterEntry(entry)" @mouseleave="leaveEntry(entry)">
                <td class="tracker-entries-entry-project">
                  <div class="tracker-entries-entry-project-inner">
                    <VDropdown @apply-show="showedActionsDropdown(entry)" @apply-hide="hidActionsDropdown(entry)">
                      <Transition name="tracker-entries-entry-actions-fade">
                        <Icon :src="dropdownIcon" class="tracker-entries-entry-actions-dropdown" v-show="entry.actionsShow || entry.actionsDropdownShow || isTouchDevice" />
                      </Transition>

                      <template #popper>
                        <a v-if="entry.user_id === $store.state.shared.user.user_id" class="dropdown-item" title="Edit entry" @click="editEntry(entry)" v-close-popper>
                          <Icon :src="editIcon" /> Edit entry
                        </a>
                        <a class="dropdown-item" title="Delete entry" @click="deleteEntryConfirm(entry)" v-close-popper>
                          <Icon :src="minusIcon" /> Remove entry
                        </a>
                        <a class="dropdown-item" title="Clone entry" @click="cloneEntry(entry)" v-close-popper>
                          <Icon :src="cloneIcon" /> Clone entry
                        </a>
                      </template>
                    </VDropdown>

                    {{ entry.project }}
                  </div>
                </td>
                <td class="tracker-entries-entry-category">{{ entry.category }}</td>
                <td class="tracker-entries-entry-decimal-time">{{ entry.decimal_time }}</td>
                <td class="tracker-entries-entry-username" v-if="$store.state.shared.user.sudoMode">{{ entry.email }}</td>
              </tr>

              <tr class="tracker-entries-entry-description" v-if="entry.description">
                <td colspan="5">{{ entry.description }}</td>
              </tr>
            </template>

            <tr class="tracker-entries-entry-separator">
              <td colspan="5"></td>
            </tr>
          </tbody>
        </template>
      </table>
    </div>
  </div>

  <Modal
    v-model="deleteEntryModalStatus"
    title="Remove entry"
    @confirm="deleteEntry()"
    @cancel="deleteEntryModalStatus = false"
  >
    Are you sure you remove the entry?
  </Modal>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import dayjs from 'dayjs'
  import minusIcon from '@/images/minus.svg'
  import cloneIcon from '@/images/clone.svg'
  import editIcon from '@/images/edit.svg'
  import dropdownIcon from '@/images/dropdown.svg'
  import { redirectToSelectedMonth } from '@/router/index'
  import Modal from '@/components/Shared/Modal.vue'
  import { hideAllPoppers } from 'floating-vue'

  export default {
    name: 'Entries',
    components: {
      Icon,
      Modal,
    },
    data() {
      return {
        minusIcon,
        cloneIcon,
        editIcon,
        dropdownIcon,
        redirectToSelectedMonth,
        deleteEntryModalStatus: false,
        deleteEntryCurrent: null,
        actionsShow: false,
      }
    },
    computed: {
      entriesByDate() {
        let entriesByDate = {}

        for (const entry of this.$store.state.tracker.entries) {
          const date = entry.entry_date

          if (entriesByDate[date]) {
            entriesByDate[date].push(entry)
          } else {
            entriesByDate[date] = [entry]
          }
        }

        entriesByDate = Object.keys(entriesByDate).sort().reverse().reduce(
          (obj, key) => {
            obj[key] = entriesByDate[key]
            return obj
          },
          {}
        )

        return entriesByDate
      },
      activeUsersString() {
        return this.$store.state.shared.user.sudo_users.join(', ')
      }
    },
    methods: {
      isNewDay(date) {
        const dates = Object.keys(this.entriesByDate)
        const index = dates.indexOf(date)

        return index === 0 || this.entriesByDate[dates[index - 1]][0].entry_date !== date
      },
      cloneEntry(entry) {
        this.makeSureToCloseDropdown()

        const cloneEntry = JSON.parse(JSON.stringify(entry))
        cloneEntry.id = null
        cloneEntry.entry_date = dayjs().format('MMMM D, YYYY')
        this.$store.dispatch('tracker/setFormMode', 'create')
        this.$store.dispatch('tracker/setFormEntry', cloneEntry)
        this.mitt.emit('cloneEntry')
      },
      editEntry(entry) {
        this.makeSureToCloseDropdown()

        const cloneEntry = JSON.parse(JSON.stringify(entry))
        cloneEntry.entry_date = dayjs(cloneEntry.entry_date).format('MMMM D, YYYY')
        this.$store.dispatch('tracker/setFormMode', 'edit')
        this.$store.dispatch('tracker/setFormEntry', cloneEntry)
        this.mitt.emit('editEntry')
      },
      deleteEntryConfirm(entry) {
        this.makeSureToCloseDropdown()

        this.deleteEntryModalStatus = true
        this.deleteEntryCurrent = entry
      },
      makeSureToCloseDropdown() {
        // FIXME: Quick fix to make sure the dropdown is always closed on mobile devices due to
        // https://github.com/Akryum/floating-vue/issues/927
        hideAllPoppers()
      },
      async deleteEntry() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('tracker/deleteEntry', this.deleteEntryCurrent)

        if (response.ok) {
          const months = await this.$store.dispatch('tracker/fetchMonths')

          this.$store.dispatch('tracker/setMonths', months)
          this.$store.dispatch('tracker/reloadViewData', ['popular', 'dailyTotals', 'totals'])

          this.redirectToSelectedMonth(this.$store)
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
        this.deleteEntryModalStatus = false
      },
      async unSudo() {
        this.mitt.emit('spinnerStart')

        const response = await this.$store.dispatch('admin/unsudoUsersTimesheet')

        if (response.ok) {
          const months = await this.$store.dispatch('tracker/fetchMonths')

          this.$store.dispatch('tracker/setMonths', months)
          this.$store.dispatch('tracker/reloadViewData', ['popular', 'dailyTotals', 'totals', 'entries'])

          const user = await this.$store.dispatch('shared/fetchUser')

          this.$store.dispatch('shared/setUser', user)

          this.redirectToSelectedMonth(this.$store)

          this.awn.success('Showing only your timesheets.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
      formatDate(date) {
        const dateParsed = Date.parse(date)
        const dateFormatted = dayjs(dateParsed).format('dddd, YYYY-MM-DD')

        return dateFormatted
      },
      enterEntry(entry) {
        this.actionsShow = true
        entry.actionsShow = true
      },
      leaveEntry(entry) {
        this.actionsShow = false
        entry.actionsShow = false
      },
      showedActionsDropdown(entry) {
        entry.actionsDropdownShow = true
      },
      hidActionsDropdown(entry) {
        entry.actionsDropdownShow = false
      },
    }
  }
</script>

<style lang="scss">
  .tracker-entries {
    width: 100%;
    background-color: #f2eeed;

    .tracker-entries-date-cell {
      text-align: center;
    }

    .tracker-entries-date-row + .entry {
      td {
        border-top-width: 0.1rem;
      }
    }

    .tracker-entries-entry-description {
      white-space: pre-wrap;
      word-break: break-word;
      background-color: #f5f5f5;
    }

    .tracker-entries-date-row,
    th,
    .tracker-entries-entry:hover,
    .tracker-entries-entry:hover + tr.tracker-entries-entry-description {
      background-color: #fff;
    }

    .tracker-entries-entry-actions-dropdown {
      width: 3rem;
      height: 3rem;
      padding: 0.3rem;
      margin-left: -0.5rem;
    }

    .tracker-entries-entry-actions-fade-enter-active {
      transition: opacity 0.5s ease;
      opacity: 1;
    }

    .tracker-entries-entry-actions-fade-enter-from {
      opacity: 0;
    }

    td.tracker-entries-entry-project {
      line-height: 3.5rem;

      .tracker-entries-entry-project-inner {
        display: flex;
      }
    }

    td,
    th {
      border-width: 0.1rem !important;
      vertical-align: middle !important;
    }

    td.tracker-entries-entry-category,
    td.tracker-entries-entry-project {
      width: 32%;
    }

    @media screen and (min-width: 1400px) {
      td.tracker-entries-entry-category,
      td.tracker-entries-entry-project {
        width: 35%;
      }

      td.tracker-entries-entry-actions {
        width: 10%;
      }
    }

    @media screen and (min-width: 2100px) {
      td.tracker-entries-entry-category,
      td.tracker-entries-entry-project {
        width: 38%;
      }

      td.tracker-entries-entry-actions {
        width: 5%;
      }
    }

    td.tracker-entries-entry-project {
      border-left: none;
    }

    td.tracker-entries-entry-decimal-time,
    td.tracker-entries-entry-username {
      width: 15%;
    }

    tbody {
      .tracker-entries-entry-separator {
        background-color: #fff;

        &:last-child {
          display: none;
        }
      }
    }
  }

  .tracker-entries-wrapper {
    overflow-x: auto;
  }
</style>
