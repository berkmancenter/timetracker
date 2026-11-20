module Timetracker
  # The time entries of the demo data (see Timetracker::DemoData): the ones
  # written in the data file, and generated ones for every member with
  # hours_per_week, on weekdays from the day they joined (at most
  # history_days back).
  class DemoTimeEntries
    # A member logs time on about this share of the weekdays,
    WORKING_DAY_CHANCE = 0.8
    # and sometimes splits the day into two entries.
    SECOND_ENTRY_CHANCE = 0.25

    def initialize(history_days:, random_seed:)
      @history_days = history_days
      @random = Random.new(random_seed)
    end

    # Replaces the entries of the demo users in the timesheet, entries of other
    # people stay.
    def load(timesheet, data, users, fields)
      entries = TimeEntry.where(timesheet: timesheet, user_id: users.values.map(&:id))
      CustomFieldDataItem.where(owner_type: 'TimeEntry', owner_id: entries.select(:id)).delete_all
      entries.delete_all

      new_entries = written_entries(data, users) + generated_entries(data, users)
      check_fields(timesheet, new_entries, fields)
      insert(timesheet, new_entries, fields)
    end

    private

    def written_entries(data, users)
      Array(data[:entries]).map do |entry|
        {
          user: users.fetch(entry[:user].to_sym),
          date: DemoData.date(entry[:date]),
          hours: entry[:hours],
          values: entry.except(:user, :date, :hours)
        }
      end
    end

    def generated_entries(data, users)
      values = data.fetch(:generated, {})

      data[:members].select { |member| member[:hours_per_week] }.flat_map do |member|
        user = users.fetch(member[:user].to_sym)
        first_day = [DemoData.date(member[:joined]), Date.current - @history_days].max
        last_day = Date.current - 1 - member.fetch(:pause_days, 0)

        (first_day..last_day).select(&:on_weekday?).flat_map do |day|
          next [] unless @random.rand < WORKING_DAY_CHANCE

          day_entries(user, day, member[:hours_per_week], values)
        end
      end
    end

    def day_entries(user, day, hours_per_week, values)
      hours = quarter_hours(hours_per_week / 5.0 / WORKING_DAY_CHANCE * (0.5 + @random.rand))
      parts = hours >= 1 && @random.rand < SECOND_ENTRY_CHANCE ? split(hours) : [hours]

      parts.map do |part|
        { user: user, date: day, hours: part, values: values.transform_values { |list| pick(list) } }
      end
    end

    def split(hours)
      first = quarter_hours(hours * (0.3 + (@random.rand * 0.4)))
      [first, hours - first]
    end

    # Like the entry form: at least 0.25, in steps of 0.25.
    def quarter_hours(hours)
      [(hours * 4).round / 4.0, 0.25].max
    end

    # Values earlier in the list come up more often.
    def pick(list)
      list[((@random.rand**2) * list.size).floor]
    end

    def check_fields(timesheet, entries, fields)
      unknown = entries.flat_map { |entry| entry[:values].keys }.uniq - fields.keys
      return if unknown.empty?

      raise ArgumentError, "Unknown fields #{unknown.join(', ')} in the time entries of #{timesheet.name}"
    end

    # Hundreds of rows, one insert each for entries and field values.
    def insert(timesheet, entries, fields)
      return if entries.empty?

      rows = entries.map do |entry|
        logged_at = logged_at(entry[:date])
        {
          user_id: entry[:user].id,
          timesheet_id: timesheet.id,
          entry_date: entry[:date],
          decimal_time: entry[:hours],
          created_at: logged_at,
          updated_at: logged_at
        }
      end
      ids = TimeEntry.insert_all!(rows, returning: [:id], record_timestamps: false).rows.flatten

      items = entries.zip(rows, ids).flat_map do |entry, row, id|
        entry[:values].filter_map do |machine_name, value|
          next if value.blank?

          {
            custom_field_id: fields.fetch(machine_name).id,
            owner_type: 'TimeEntry',
            owner_id: id,
            value: value,
            created_at: row[:created_at],
            updated_at: row[:created_at]
          }
        end
      end
      CustomFieldDataItem.insert_all!(items, record_timestamps: false) if items.any?
    end

    # Logged at the end of the working day, or now for today's entries.
    def logged_at(date)
      [date.in_time_zone.change(hour: 17), Time.current].min
    end
  end
end
