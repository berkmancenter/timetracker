class Period < ActiveRecord::Base
  validates :name, presence: true
  validates :from, presence: true
  validates :to, presence: true
  validates :timesheet, presence: true

  has_many :credits, dependent: :destroy, autosave: true
  has_many :custom_fields, -> { order(:order) }, as: :customizable, dependent: :destroy
  belongs_to :timesheet

  accepts_nested_attributes_for :custom_fields, allow_destroy: true

  def get_stats(user_ids = nil)
    total_num_of_days = (self.to - self.from).to_f
    current_num_of_days = (Date.today - self.from).to_f
    current_passed = current_num_of_days / total_num_of_days
    current_passed = 1 if current_passed > 1

    query = User
            .select('
              users.id AS user_id,
              users.username,
              users.email,
              users.first_name,
              users.last_name,
              COALESCE(SUM(time_entries.decimal_time), 0) AS total_hours,
              credits.amount AS credits,
              ARRAY_AGG(DISTINCT(users_timesheets.role)) AS roles,
              COALESCE(MAX(time_entries.entry_date), NULL) AS last_entry_date
            ')
            .joins("
              LEFT JOIN
                time_entries ON
                  time_entries.user_id = users.id
                  AND
                  (time_entries.entry_date >= '#{self.from}' AND time_entries.entry_date <= '#{self.to}')"
            )
            .joins(:credits)
            .joins(:users_timesheets)
            .where('time_entries.timesheet_id = ?', self.timesheet_id)
            .where('users_timesheets.timesheet_id = ?', self.timesheet_id)
            .where('credits.period_id = ?', self.id)

    # Filter by specific user_ids if provided
    if user_ids.present?
      user_id_array = user_ids.split(',').map(&:to_i)
      query = query.where('users.id IN (?)', user_id_array)
    end

    query = query.group('users.username, users.email, users.id, credits.amount')
                 .order('users.username')

    results = query.map do |record|
      record = record.attributes
      record['admin'] = self.timesheet.admin?(User.find(record['user_id']))
      record['should_hours'] = current_passed * record['credits']
      record['balance'] = format('%.2f', record['total_hours'] - record['should_hours'])
      record['balance_percent'] = format('%.2f', (record['total_hours'] / record['should_hours']) * 100)
      record['should_hours'] = format('%.2f', record['should_hours'])
      record['total_hours'] = format('%.2f', record['total_hours'])
      record['credits'] = format('%.2f', record['credits'])
      record
    end

    # Add custom field values if any custom fields exist
    if custom_fields.any?
      # Get all user IDs from the results
      user_ids_from_results = results.map { |r| r['user_id'] }

      # Fetch all custom field data for these users in one query
      custom_field_data = {}
      CustomFieldDataItem.where(
        custom_field_id: custom_fields.pluck(:id),
        item_id: user_ids_from_results
      ).each do |item|
        custom_field_data[item.item_id] ||= {}
        custom_field_data[item.item_id][item.custom_field_id] = item.value
      end

      # Add custom field data to each result
      results.each do |record|
        user_id = record['user_id']
        if custom_field_data[user_id]
          custom_fields.each do |field|
            record["custom_field_#{field.id}"] = custom_field_data[user_id][field.id] || ''
          end
        else
          custom_fields.each do |field|
            record["custom_field_#{field.id}"] = ''
          end
        end
      end
    end

    results
  end

  def self.user_periods(user)
    return Period.all if user.superadmin

    Period.joins(timesheet: :users_timesheets)
          .where(
            users_timesheets: {
              user_id: user.id,
              role: 'admin'
            }
          )
  end

  def self.timesheet_periods(timesheet)
    Period.where(timesheet_id: timesheet.id)
  end

  def self.user_periods_for_timesheet(user, timesheet)
    return Period.all if user.superadmin

    Period.joins(timesheet: :users_timesheets)
          .where(
            users_timesheets: {
              user_id: user.id,
              role: 'admin'
            },
            periods: {
              timesheet_id: timesheet.id
            }
          )
  end

  def self.admin_periods_for_timesheet(timesheet)
    return Period.all if timesheet.superadmin

    Period.joins(:users_timesheets)
          .where(
            users_timesheets: {
              timesheet_id: timesheet.id,
              role: 'admin'
            }
          )
  end
end
