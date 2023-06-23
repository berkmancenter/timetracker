<template>
  <div>
    <h4 class="is-size-4 mt-2">Existing entries</h4>

    <article v-if="$store.state.shared.user.active_users.length > 1" class="message is-warning">
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
            <th>Actions</th>
            <th>Category</th>
            <th>Project</th>
            <th>Hours</th>
            <th v-if="$store.state.shared.user.sudoMode">Username</th>
          </tr>
        </thead>
        <template v-for="(entries, date) in entriesByDate">
          <tbody>
            <tr class="entry-date">
              <td colspan="5" class="entry_date is-size-4" v-if="isNewDay(date)">{{ date }}</td>
            </tr>

            <template v-for="entry in entries" :key="entry.id">
              <tr class="entry">
                <td>
                  <a title="Delete this entry" class="entry-delete" @click="deleteEntry(entry)">
                    <Icon :src="minusIcon" />
                  </a>
                  <a title="Clone this entry" class="entry-clone" @click="cloneEntry(entry)">
                    <Icon :src="cloneIcon" />
                  </a>
                  <a v-if="entry.user_id === $store.state.shared.user.user_id" title="Edit this entry" class="entry-edit" @click="editEntry(entry)">
                    <Icon :src="editIcon" />
                  </a>
                </td>
                <td class="category">{{ entry.category }}</td>
                <td class="project">{{ entry.project }}</td>
                <td class="decimal_time">{{ entry.decimal_time }}</td>
                <td class="username" v-if="$store.state.shared.user.sudoMode">{{ entry.username }}</td>
              </tr>

              <tr v-if="entry.description">
                <td colspan="5" class="description">{{ entry.description }}</td>
              </tr>
            </template>

            <tr class="separator">
              <td colspan="5"></td>
            </tr>
          </tbody>
        </template>
      </table>
    </div>
  </div>
</template>

<script>
  import Icon from '@/components/Shared/Icon.vue'
  import Swal from 'sweetalert2'
  import dayjs from 'dayjs'
  import minusIcon from '@/images/minus.svg'
  import cloneIcon from '@/images/time_clone.svg'
  import editIcon from '@/images/time_edit.svg'

  export default {
    name: 'Entries',
    components: {
      Icon,
    },
    data() {
      return {
        minusIcon,
        cloneIcon,
        editIcon,
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
        return this.$store.state.shared.user.active_users.join(', ')
      }
    },
    methods: {
      isNewDay(date) {
        const dates = Object.keys(this.entriesByDate);
        const index = dates.indexOf(date);

        return index === 0 || this.entriesByDate[dates[index - 1]][0].entry_date !== date;
      },
      cloneEntry(entry) {
        const cloneEntry = JSON.parse(JSON.stringify(entry))
        cloneEntry.id = null
        cloneEntry.entry_date = dayjs().format('MMMM D, YYYY')
        this.$store.dispatch('tracker/setFormMode', 'create')
        this.$store.dispatch('tracker/setFormEntry', cloneEntry)
        this.mitt.emit('cloneEntry')
      },
      editEntry(entry) {
        const cloneEntry = JSON.parse(JSON.stringify(entry))
        cloneEntry.entry_date = dayjs(cloneEntry.entry_date).format('MMMM D, YYYY')
        this.$store.dispatch('tracker/setFormMode', 'edit')
        this.$store.dispatch('tracker/setFormEntry', cloneEntry)
        this.mitt.emit('editEntry')
      },
      deleteEntry(entry) {
        Swal.fire({
          title: 'Removing Entry',
          text: `Are you sure want to remove?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: this.colors.main,
        }).then(async (result) => {
          if (result.isConfirmed) {
            await this.$store.dispatch('tracker/deleteEntry', entry)
            const months = await this.$store.dispatch('tracker/fetchMonths')

            this.$store.dispatch('tracker/setMonths', months)
            this.$store.dispatch('tracker/reloadViewData', ['popular', 'dailyTotals'])
          }
        })
      },
      async unSudo() {
        const response = await this.$store.dispatch('admin/unSudo')

        if (response.ok) {
          const user = await this.$store.dispatch('shared/fetchUser')
          await this.$store.dispatch('tracker/reloadViewData')

          this.$store.dispatch('shared/setUser', user)
          this.awn.success('Showing only your timesheets.')
        } else {
          this.awn.warning('Something went wrong, try again.')
        }
      },
    }
  }
</script>

<style lang="scss">
  .tracker-entries {
    width: 100%;
    background-color: #f2eeed;

    .entry_date {
      text-align: center;
    }

    .entry {
      td {
        border-bottom: none;
      }

      td:first-child {
        text-align: center;
        min-width: 12rem;

        img {
          width: 3rem;
        }
      }
    }

    .entry-date + .entry {
      td {
        border-top-width: 0.1rem;
      }
    }

    .description {
      white-space: pre-wrap;
      word-break: break-word;
      background-color: #f5f5f5;
    }

    .entry-date,
    th {
      background-color: #fff;
    }

    td,
    th {
      border-width: 0.1rem !important;
      vertical-align: middle !important;
    }

    td.category,
    td.project {
      width: 32%;
    }

    @media screen and (min-width: 1400px) {
      td.category,
      td.project {
        width: 35%;
      }
    }

    @media screen and (min-width: 2100px) {
      td.category,
      td.project {
        width: 38%;
      }
    }

    td.decimal_time,
    td.username {
      width: 15%;
    }

    tbody {
      .separator {
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
