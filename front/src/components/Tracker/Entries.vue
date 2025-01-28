<template>
  <div class="tracker-entries">
    <div v-if="$store.state.shared.user.sudoMode" class="message is-warning mt-2">
      <div class="message-body">
        <div><strong>You are viewing time entries of</strong></div>
        {{ activeUsersString }}
        <div>
          <a class="button mt-2" @click="unSudo()">Show only my entries</a>
        </div>
      </div>
    </div>

    <div class="tracker-entries-wrapper" :class="{ 'tracker-entries-sudo': $store.state.shared.user.sudoMode }">
      <div class="tracker-entries-header">
        <div v-for="field in $store.state.tracker.selectedTimesheet.timesheet_fields.filter(field => field.list)">
          {{ field.title }}
        </div>
        <div v-if="$store.state.shared.user.sudoMode">Email</div>
      </div>

      <div>
        <TransitionGroup name="entry-item-fade" :css="$store.state.tracker.entriesBeforeChange === false">
          <template v-for="(entries, date) in entriesByDate" :key="date">
          <div>
            <div class="tracker-entries-date-row">
              <div class="tracker-entries-date-cell is-size-4" v-if="isNewDay(date)">{{ formatDate(date) }}</div>
            </div>

            <div class="tracker-entries-day">
              <TransitionGroup name="entry-item-fade" :css="$store.state.tracker.entriesBeforeChange === false">
                <template v-for="entry in entries" :key="entry.id">
                  <div
                    class="tracker-entries-entry"
                    :class="{ 'tracker-entries-entry-active': entry.active, 'time-entries-entry-has-description': entry.fields.description }"
                    @mouseenter="enterEntry(entry)"
                    @mouseleave="leaveEntry(entry)"
                    @click="openMenu(entry, $event)"
                  >
                    <div class="tracker-entries-entry-meta">
                      <div class="tracker-entries-entry-field" v-for="field in this.$store.state.tracker.selectedTimesheet.timesheet_fields.filter(field => field.list)">
                        {{ entry.fields[field.machine_name] }}
                      </div>

                      <div class="tracker-entries-entry-email" v-if="$store.state.shared.user.sudoMode">
                        {{ entry.email }}
                      </div>
                    </div>

                    <div
                      class="tracker-entries-entry-description"
                      title="Description"
                      v-if="entry.fields.description"
                    >
                      {{ entry.fields.description }}
                    </div>

                    <div class="tracker-entries-entry-decimal-time">{{ entry.decimal_time }}</div>
                    <div class="tracker-entries-entry-top-bar"></div>

                    <VDropdown
                      :ref="`entry${entry.id}Menu`"
                      class="tracker-entries-entry-actions-dropdown"
                      placement="right"
                      :referenceNode="() => $refs[`entry${entry.id}MenuRef`][0]"
                      @apply-hide="closeMenu(entry)"
                    >
                      <div :ref="`entry${entry.id}MenuRef`" class="tracker-entries-entry-actions-dropdown-ref-item"></div>

                      <template #popper>
                        <a
                          v-if="entry.user_id === $store.state.shared.user.user_id"
                          class="dropdown-item"
                          title="Edit entry"
                          @click="editEntry(entry)"
                          v-close-popper
                        >
                          <Icon :src="editIcon" /> Edit entry
                        </a>
                        <a
                          class="dropdown-item"
                          title="Delete entry"
                          @click="deleteEntryConfirm(entry)"
                          v-close-popper
                        >
                          <Icon :src="minusIcon" /> Remove entry
                        </a>
                        <a
                          class="dropdown-item"
                          title="Clone entry"
                          @click="cloneEntry(entry)"
                          v-close-popper
                        >
                          <Icon :src="cloneIcon" /> Clone entry
                        </a>
                      </template>
                    </VDropdown>
                  </div>
                </template>
              </TransitionGroup>
            </div>
          </div>
        </template>
        </TransitionGroup>
      </div>
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
  import utc from 'dayjs/plugin/utc'
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
          this.$store.dispatch('tracker/setSelectedMonthFromRoute')
          this.$store.dispatch('tracker/reloadViewData', ['popular', 'periodTotals', 'totals'])

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
          this.$store.dispatch('tracker/setSelectedMonthFromRoute')
          this.$store.dispatch('tracker/reloadViewData', ['popular', 'periodTotals', 'totals', 'entries'])

          const user = await this.$store.dispatch('shared/fetchUser')

          this.$store.dispatch('shared/setUser', user)

          this.redirectToSelectedMonth(this.$store)
        } else {
          this.awn.warning('Something went wrong, try again.')
        }

        this.mitt.emit('spinnerStop')
      },
      formatDate(date) {
        dayjs.extend(utc)

        const dateParsed = Date.parse(date)
        const dateFormatted = dayjs(dateParsed).utc().format('dddd, YYYY-MM-DD')

        return dateFormatted
      },
      enterEntry(entry) {
        entry.active = true
      },
      leaveEntry(entry) {
        if (!entry.menuOpen) {
          entry.active = false
        }
      },
      openMenu(entry, event) {
        entry.menuOpen = true

        let parentElem = this.$refs[`entry${entry.id}MenuRef`][0].offsetParent
        let parentRect = parentElem.getBoundingClientRect()

        // Calculate the local coordinates relative to the parent element
        // We need to use the ref element because the library doesn't provide
        // the show-next-to-click-location functionality nativelly
        let refElem = this.$refs[`entry${entry.id}MenuRef`][0]
        refElem.style.left = `${event.clientX - parentRect.left}px`
        refElem.style.top = `${event.clientY - parentRect.top}px`

        // Hide and show the dropdown menu to update its position
        this.$refs[`entry${entry.id}Menu`][0].hide()
        this.$refs[`entry${entry.id}Menu`][0].show()

        entry.active = true
      },
      closeMenu(entry) {
        entry.active = false
        entry.menuOpen = false
      },
    }
  }
</script>

<style lang="scss">
  .tracker-entries {
    .tracker-entries-header,
    .tracker-entries-date-row,
    .tracker-entries-entry-decimal-time {
      user-select: none;
    }

    &-date {
      &-cell {
        text-align: center;
      }

      &-row {
        background-color: #fff;
        margin-bottom: 1rem;

        + .entry td {
          border-top-width: 0.1rem;
        }
      }
    }

    &-entry {
      border-radius: 0.5rem;
      transition: box-shadow 0.3s ease, transform 0.3s ease;
      cursor: pointer;

      &-active {
        box-shadow: 0 0 10px var(--blue-stronger-color);
      }

      padding: 1.75rem 0 0 0;
      box-shadow: 0 1px 0.5rem 0 rgba(32, 33, 36, 0.28);
      margin-bottom: 1rem;
      margin-left: 1rem;
      margin-right: 1rem;
      position: relative;

      > *:last-child {
        padding: 0;
      }

      &-description {
        white-space: pre-wrap;
        word-break: break-word;
        padding: 0.5rem;
      }

      &-meta {
        display: flex;
        width: 100%;

        > * {
          width: 50%;
          padding: 0.5rem;
          border-right: 1px solid var(--grey-from-bulma);

          &:last-child {
            border-right: none;
          }
        }
      }

      &-actions {
        &-dropdown {
          &-ref-item {
            position: absolute;
            width: 1px;
            height: 1px;
          }

          img {
            padding: 0;
          }
        }

        &-fade-enter {
          &-active {
            transition: opacity 0.5s ease;
            opacity: 1;
          }

          &-from {
            opacity: 0;
          }
        }
      }

      &-field,
      &-description,
      &-email {
        display: flex;
        flex-wrap: nowrap;
        align-items: center;
        word-break: break-word;
      }

      &-email {
        margin-left: auto;
      }

      &-decimal-time {
        position: absolute;
        top: 0;
        right: 0;
        background-color: var(--main-color);
        color: #fff;
        z-index: 2;
        font-weight: bold;
        height: 1.75rem;
        display: flex;
        align-items: center;
        padding: 0.25rem;
        width: 3.5rem;
        justify-content: center;
        border-radius: 0 0.5rem 0 0;
      }

      &-top-bar {
        position: absolute;
        top: 0;
        left: 0;
        margin: 0 auto;
        height: 1.75rem;
        width: 100%;
        background-color: var(--super-light-color);
        z-index: 1;
        border-radius: 0.5rem 0.5rem 0 0;
      }

      &-tag {
        background-color: var(--main-color);
        color: #fff;
        border-radius: 0.5rem;
        margin-right: 1rem;
        margin-left: 1rem;
        height: 2rem;
        width: 2rem;
        min-width: 2rem;
        min-height: 2rem;
        display: flex;
        align-items: center;
        justify-content: center;
        user-select: none;
      }
    }

    &-wrapper {
      overflow-x: auto;
    }

    &-header {
      display: flex;
      font-weight: bold;
      margin-left: 1rem;
      margin-right: 1rem;
      margin-bottom: 0.5rem;
      border-bottom: 1px solid var(--grey-from-bulma);

      > * {
        width: 50%;
        border-right: 1px solid var(--grey-from-bulma);
        padding: 0.5rem;
      }
    }

    &-sudo {
      .tracker-entries-header,
      .tracker-entries-entry-meta {
        > * {
          width: 33%;
          flex-grow: 1;
        }
      }

      .tracker-entries-entry-meta {
        &:last-child {
          border-right: 1px solid var(--grey-from-bulma);
        }
      }
    }
  }

  .time-entries-entry-has-description {
    .tracker-entries-entry-meta {
      border-bottom: 1px solid var(--grey-from-bulma);
    }
  }

  @media all and (max-width: 1300px) {
    .tracker-entries {
      &-entry {
        margin-left: 0;
        margin-right: 0;

        &-meta {
          width: 100%;
        }
      }
    }

    .tracker-entries-wrapper {
      padding: 0 0.5rem;
    }
  }

  // Animations
  .entry-item-fade-enter-active,
  .entry-item-fade-leave-active {
    transition: opacity 0.5s ease;
  }

  .entry-item-fade-enter-from,
  .entry-item-fade-leave-to {
    opacity: 0;
  }
</style>
