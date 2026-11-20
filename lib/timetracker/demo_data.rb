module Timetracker
  # Demo data to play with: people in different roles, timesheets with their
  # own fields, months of time entries, periods with hours to work and
  # invitations in every state. The data itself is in db/seeds/demo_data.yml,
  # see "Demo data" in README.md.
  #
  # Every run gives the same data (fixed random seed, dates relative to today).
  # Demo users have a @demo.timetracker.test email and demo timesheets a UUID
  # made from their key, that's how demo data is told apart from real data:
  # loading again puts the demo data back to its starting state, removing it
  # leaves everything else alone.
  class DemoData
    DOMAIN = 'demo.timetracker.test'.freeze
    DATA_FILE = Rails.root.join('db/seeds/demo_data.yml')
    DEFAULT_PASSWORD = 'timetracker-demo-password'.freeze
    DEFAULT_HISTORY_DAYS = 240
    DEFAULT_RANDOM_SEED = 2012
    RELATIVE_DATE = /\A(?:(?<today>today)|(?<ago>\d+) (?<ago_unit>day|week)s? ago|in (?<in>\d+) (?<in_unit>day|week)s?)\z/

    class NotAllowed < StandardError; end

    def self.from_env
      new(
        history_days: Integer(ENV['DEMO_HISTORY_DAYS'].presence || DEFAULT_HISTORY_DAYS),
        password: ENV['DEMO_PASSWORD'].presence || DEFAULT_PASSWORD,
        random_seed: Integer(ENV['DEMO_RANDOM_SEED'].presence || DEFAULT_RANDOM_SEED)
      )
    end

    # Demo accounts have a known password, so only in development and test
    # unless asked for (e.g. a demo server).
    def self.allowed?
      Rails.env.local? || ENV['ALLOW_DEMO_DATA'] == 'true'
    end

    def self.email_for(key)
      "#{key}@#{DOMAIN}"
    end

    # The same key always gives the same UUID, so the links to a demo
    # timesheet stay the same when it's loaded again.
    def self.uuid_for(key)
      Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "https://#{DOMAIN}/timesheets/#{key}")
    end

    # "3 days ago", "in 2 weeks" or "today" in the data file.
    def self.time(text)
      match = RELATIVE_DATE.match(text.to_s)
      unless match
        raise ArgumentError,
              "Unknown date #{text.inspect} in #{DATA_FILE}, use e.g. \"3 days ago\", \"in 2 weeks\" or \"today\""
      end

      return Time.current if match[:today]
      return match[:ago].to_i.public_send(match[:ago_unit]).ago if match[:ago]

      match[:in].to_i.public_send(match[:in_unit]).from_now
    end

    def self.date(text)
      time(text).to_date
    end

    attr_reader :password, :skipped_codes

    def initialize(
      history_days: DEFAULT_HISTORY_DAYS,
      password: DEFAULT_PASSWORD,
      random_seed: DEFAULT_RANDOM_SEED
    )
      @history_days = history_days
      @password = password
      @random_seed = random_seed
      @data = YAML.load_file(DATA_FILE, symbolize_names: true)
      @skipped_codes = []
    end

    def load!
      ensure_allowed!
      @skipped_codes = []
      time_entries = DemoTimeEntries.new(history_days: @history_days, random_seed: @random_seed)

      ActiveRecord::Base.transaction do
        @users = DemoUsers.new(users_data, password: password).load
        # Accounts made while playing, e.g. signed up for an invitation.
        destroy_users(demo_users.where.not(id: demo_user_ids))

        timesheets_data.each do |data|
          timesheet, fields = load_timesheet(data)
          load_memberships(timesheet, data)
          time_entries.load(timesheet, data, @users, fields)
          load_periods(timesheet, data)
          load_invitations(timesheet, data)
        end
      end
      self
    end

    def remove!
      ensure_allowed!
      ActiveRecord::Base.transaction do
        timesheet_ids = demo_timesheets.pluck(:id)
        remove_time_entries(TimeEntry.where(timesheet_id: timesheet_ids))
        Invitation.where(timesheet_id: timesheet_ids).delete_all
        Timesheet.where(id: timesheet_ids).destroy_all
        destroy_users(demo_users)
      end
      self
    end

    def reset!
      remove!
      load!
    end

    def report
      DemoReport.new(self).to_s
    end

    def users_data
      @data[:users]
    end

    def timesheets_data
      @data[:timesheets]
    end

    def demo_users
      User.where('email LIKE ?', "%@#{DOMAIN}")
    end

    def demo_timesheets
      Timesheet.where(uuid: timesheets_data.map { |data| self.class.uuid_for(data[:key]) })
    end

    def demo_timesheet(key)
      Timesheet.find_by(uuid: self.class.uuid_for(key))
    end

    private

    def ensure_allowed!
      return if self.class.allowed?

      raise NotAllowed,
            'The demo data has accounts with a known password, so it only loads in development and test. ' \
            'Set ALLOW_DEMO_DATA=true to load it anyway (for example on a demo server).'
    end

    def demo_user_ids
      @users.values.map(&:id)
    end

    def user(key)
      @users.fetch(key.to_sym)
    end

    def load_timesheet(data)
      timesheet = Timesheet.find_or_initialize_by(uuid: self.class.uuid_for(data[:key]))
      timesheet.name = data[:name]
      timesheet.created_at = self.class.time(data[:created]) if data[:created]
      timesheet.save!

      [timesheet, load_custom_fields(timesheet, data[:fields])]
    end

    # Fields are found by machine name, fields added while playing are removed.
    # Returns the fields by machine name.
    def load_custom_fields(owner, fields_data)
      fields_data = Array(fields_data).map do |field|
        field.merge(machine_name: field[:machine_name] || field[:title].parameterize.underscore)
      end
      owner.custom_fields.where.not(machine_name: fields_data.pluck(:machine_name)).destroy_all

      fields_data.each_with_index.to_h do |field, index|
        custom_field = owner.custom_fields.find_or_initialize_by(machine_name: field[:machine_name])
        custom_field.update!(
          title: field[:title],
          description: field[:description],
          input_type: field.fetch(:input_type, 'text'),
          order: index + 1,
          popular: field.fetch(:popular, false),
          list: field.fetch(:list, false),
          required: false,
          access_key: field[:access_key]
        )
        [custom_field.machine_name.to_sym, custom_field]
      end
    end

    # Only memberships of demo users, other people who joined a demo timesheet
    # stay.
    def load_memberships(timesheet, data)
      UsersTimesheet.where(timesheet: timesheet, user_id: demo_user_ids).delete_all

      data[:members].each do |member|
        joined = self.class.time(member[:joined])
        UsersTimesheet.create!(
          timesheet: timesheet,
          user: user(member[:user]),
          role: member[:role],
          created_at: joined,
          updated_at: joined
        )
      end
    end

    # Periods are found by name, periods added while playing (e.g. a clone)
    # are removed.
    def load_periods(timesheet, data)
      periods_data = Array(data[:periods])
      timesheet.periods.where.not(name: periods_data.pluck(:name)).destroy_all

      periods_data.each do |period_data|
        period = timesheet.periods.find_or_initialize_by(name: period_data[:name])
        period.update!(from: self.class.date(period_data[:from]), to: self.class.date(period_data[:to]))
        fields = load_custom_fields(period, period_data[:fields])
        load_credits(period, period_data[:credits], fields)
      end
    end

    # The hours each person should work in the period, and their values of the
    # period fields.
    def load_credits(period, credits_data, fields)
      Credit.where(period: period, user_id: demo_user_ids).delete_all
      CustomFieldDataItem.where(custom_field: fields.values, owner_type: 'User', owner_id: demo_user_ids).delete_all

      Array(credits_data).each do |credit|
        owner = user(credit[:user])
        Credit.create!(period: period, user: owner, amount: credit[:hours])

        unknown = credit.keys - %i[user hours] - fields.keys
        raise ArgumentError, "Unknown period fields #{unknown.join(', ')} in #{period.name}" if unknown.any?

        fields.each do |machine_name, field|
          next if credit[machine_name].blank?

          CustomFieldDataItem.create!(custom_field: field, owner: owner, value: credit[machine_name])
        end
      end
    end

    # Invitations sent by demo users are made again, so the ones answered while
    # playing can be used again.
    def load_invitations(timesheet, data)
      Invitation.where(timesheet: timesheet, sender_id: demo_user_ids).delete_all

      Array(data[:invitations]).each do |invitation|
        next skip(invitation[:code]) if Invitation.exists?(code: invitation[:code])

        sent = self.class.time(invitation[:sent])
        used_by = invitation[:used_by] && user(invitation[:used_by])
        Invitation.create!(
          timesheet: timesheet,
          code: invitation[:code],
          itype: invitation[:to] ? 'single' : 'multi',
          email: invitation[:to] && self.class.email_for(invitation[:to]),
          role: invitation[:role],
          sender: user(invitation[:by]),
          expiration: self.class.time(invitation[:expires]),
          used: used_by.present?,
          used_by: used_by,
          created_at: sent,
          updated_at: sent
        )
      end
    end

    def remove_time_entries(entries)
      CustomFieldDataItem.where(owner_type: 'TimeEntry', owner_id: entries.select(:id)).delete_all
      entries.delete_all
    end

    # Invitations they sent would block deleting them, invitations they used
    # stay, without the user.
    def destroy_users(users)
      ids = users.pluck(:id)
      return if ids.empty?

      remove_time_entries(TimeEntry.where(user_id: ids))
      Invitation.where(sender_id: ids).delete_all
      Invitation.where(used_by_id: ids).update_all(used_by_id: nil)
      User.where(id: ids).destroy_all
    end

    def skip(code)
      @skipped_codes << code
    end
  end
end
