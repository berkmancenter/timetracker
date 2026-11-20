module Timetracker
  # What is in the demo data and how to try it, printed by the demo:* tasks.
  class DemoReport
    def initialize(demo_data)
      @demo = demo_data
    end

    def to_s
      return 'No demo data loaded. Run: bin/rails demo:load' unless @demo.demo_users.exists?

      [summary, skipped, login, accounts, timesheets, things_to_try].compact.join("\n\n")
    end

    private

    def summary
      timesheets = @demo.demo_timesheets
      entries = TimeEntry.where(timesheet: timesheets)
      invitations = Invitation.where(timesheet: timesheets)
      open_invitations = invitations.where('expiration > ?', Time.current).where(used: false)

      "Demo data: #{@demo.demo_users.count} people, #{timesheets.count} timesheets, " \
        "#{number(entries.count)} time entries (#{number(entries.sum(:decimal_time).round)} hours), " \
        "#{Period.where(timesheet: timesheets).count} periods, " \
        "#{invitations.count} invitations (#{open_invitations.count} can be used)"
    end

    def skipped
      return if @demo.skipped_codes.empty?

      "Not loaded, these invitation codes are used by other invitations: #{@demo.skipped_codes.join(', ')}"
    end

    def login
      case Rails.application.config.devise_auth_type
      when 'db'
        "Log in at #{url('users/sign_in')}, every demo account has the password: #{@demo.password}"
      when 'headers'
        'Header auth: send X-Auth-Email with a demo email and X-Auth-Name with the name ' \
          '(from an address in AUTH_HEADERS_TRUSTED_PROXIES), e.g. ' \
          "curl -H 'X-Auth-Email: maya@#{DemoData::DOMAIN}' -H 'X-Auth-Name: Maya Chen' #{url('timesheets')}"
      else
        "#{Rails.application.config.devise_auth_type.upcase} log in: demo users are matched by their email."
      end
    end

    def accounts
      users = @demo.users_data
      email_width = users.map { |user| DemoData.email_for(user[:key]).length }.max
      name_width = users.map { |user| user[:name].length }.max

      rows = users.map do |user|
        "  #{DemoData.email_for(user[:key]).ljust(email_width)}  #{user[:name].ljust(name_width)}  #{user[:about]}"
      end
      "Accounts:\n#{rows.join("\n")}"
    end

    def timesheets
      rows = @demo.timesheets_data.filter_map do |data|
        timesheet = @demo.demo_timesheet(data[:key]) or next
        "  #{timesheet.name.ljust(14)} #{url(timesheet.uuid)}"
      end
      "Timesheets (time entries of the person logged in):\n#{rows.join("\n")}"
    end

    def things_to_try
      tips = [
        "Maya: add a time entry in the Research Lab, the sidebar has her most used projects and activities, " \
        'the people icon next to the month shows the entries of the others',
        "Maya: statistics of the current term, Priya is ahead and Sam behind: #{stats_url('research-lab', 'Current term')}",
        "Lea: join the Research Lab with her invitation: #{url('join/demo-lab-lea')}",
        "Tom: his invitation to the Research Lab expired: #{url('join/demo-lab-tom')}",
        "Nora (or your own account): join the Writing group with its open link: #{url('join/demo-writing-group')}",
        'Priya: Legal Clinic, "Description" is not in the table, only in the entry form and the CSV export',
        'Ada: superadmin, sees every timesheet in Timesheets'
      ]
      if Rails.application.config.devise_auth_type == 'db'
        tips << "Sign up as rosa@#{DemoData::DOMAIN}, then join the Legal Clinic as admin: #{url('join/demo-clinic-rosa')}"
      end
      "Things to try:\n#{tips.map { |tip| "  - #{tip}" }.join("\n")}"
    end

    def stats_url(timesheet_key, period_name)
      timesheet = @demo.demo_timesheet(timesheet_key)
      period = timesheet&.periods&.find_by(name: period_name)
      return url('admin/timesheets') unless period

      url("admin/timesheets/#{timesheet.id}/periods/#{period.id}/stats")
    end

    def url(path)
      "#{Rails.application.config.front_url.chomp('/')}/#{path}"
    end

    def number(value)
      ActiveSupport::NumberHelper.number_to_delimited(value)
    end
  end
end
