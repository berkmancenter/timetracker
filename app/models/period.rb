class Period < ActiveRecord::Base
  validates :name, presence: true
  validates :from, presence: true
  validates :to, presence: true
  validates :timesheet, presence: true
  validate :to_must_not_precede_from

  has_many :credits, dependent: :destroy, autosave: true
  has_many :custom_fields, -> { order(:order) }, as: :customizable, dependent: :destroy
  belongs_to :timesheet

  accepts_nested_attributes_for :custom_fields, allow_destroy: true

  def get_stats(user_ids = nil)
    current_passed = elapsed_fraction
    quoted_from = self.class.connection.quote(self.from)
    quoted_to = self.class.connection.quote(self.to)

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
                  time_entries.timesheet_id = #{self.timesheet_id.to_i}
                  AND
                  (time_entries.entry_date >= #{quoted_from} AND time_entries.entry_date <= #{quoted_to})"
            )
            .joins(:credits)
            .joins(:users_timesheets)
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
      record['should_hours'] = current_passed * record['credits'].to_d
      record['balance'] = format('%.2f', record['total_hours'] - record['should_hours'])
      record['balance_percent'] = if record['should_hours'].zero?
        '0.00'
      else
        format('%.2f', (record['total_hours'] / record['should_hours']) * 100)
      end
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
        owner_type: 'User',
        owner_id: user_ids_from_results
      ).each do |item|
        custom_field_data[item.owner_id] ||= {}
        custom_field_data[item.owner_id][item.custom_field_id] = item.value
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
    Period.where(timesheet: timesheet)
  end

  private

  def elapsed_fraction
    total_days = (self.to - self.from).to_i + 1
    return 0.0 unless total_days.positive?
    return 0.0 if Date.current < self.from
    return 1.0 if Date.current > self.to

    ((Date.current - self.from).to_i + 1).fdiv(total_days)
  end

  def to_must_not_precede_from
    return if from.blank? || to.blank? || to >= from

    errors.add(:to, 'must be on or after the start date')
  end
end
