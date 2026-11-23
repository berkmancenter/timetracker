require 'rails_helper'

RSpec.describe TimeEntriesController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #entries' do
    it 'returns time entries for the user' do
      timesheet = create(:timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :entries, params: { timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end

    it 'returns a bad request if timesheet is not found' do
      get :entries, params: { timesheet_uuid: 'non_existent_uuid' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized if user does not have access to the timesheet' do
      other_user = create(:user)
      other_timesheet = create(:timesheet)
      sign_in other_user

      get :entries, params: { timesheet_uuid: other_timesheet.uuid }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns time entries as CSV if csv param is present' do
      timesheet = create(:timesheet, :with_fields)
      entry = create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
      create(
        :custom_field_data_item,
        custom_field: timesheet.custom_fields.find_by!(machine_name: 'project'),
        owner: entry,
        value: '=HYPERLINK("https://example.test")'
      )

      get :entries, params: { timesheet_uuid: timesheet.uuid, csv: true }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/octet-stream')
      expect(response.headers['Content-Disposition']).to match(/time-entries/)
      expect(CSV.parse(response.body).flatten).to include(%q{'=HYPERLINK("https://example.test")})
    end
  end

  describe 'POST #edit' do
    it 'edits a time entry for the user' do
      timesheet = create(:timesheet, :with_fields)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      new_description = 'Updated Description'

      post :edit, params: { time_entry: { id: time_entry.id, fields: { description: new_description } }, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.single(time_entry.id).fields['description']).to eq(new_description)
    end

    it 'creates a new time entry if id is not provided' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      new_description = 'New Entry'

      post :edit, params: { time_entry: { fields: { description: new_description } }, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.single(TimeEntry.last.id).fields['description']).to eq(new_description)
    end

    it 'does not create an entry with a client-selected id' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      expect do
        post :edit, params: {
          time_entry: { id: 9_999_999, decimal_time: 1, entry_date: Date.current },
          timesheet_uuid: timesheet.uuid
        }
      end.not_to change(TimeEntry, :count)

      expect(response).to have_http_status(:bad_request)
      expect(TimeEntry.exists?(9_999_999)).to be(false)
    end

    it 'returns a bad request if timesheet is not found' do
      post :edit, params: { time_entry: { description: 'New Entry' }, timesheet_uuid: 'non_existent_uuid' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized if user does not have access to the timesheet' do
      other_user = create(:user)
      other_timesheet = create(:timesheet)
      create(:users_timesheet, user: other_user, timesheet: other_timesheet, role: 'admin')

      post :edit, params: { time_entry: { description: 'New Entry' }, timesheet_uuid: other_timesheet.uuid }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE #delete' do
    it 'deletes a time entry for the user' do
      timesheet = create(:timesheet)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)

      delete :delete, params: { id: time_entry.id }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.exists?(time_entry.id)).to be_falsey
    end

    it 'returns unauthorized if user does not have access to delete the time entry' do
      other_user = create(:user)
      timesheet = create(:timesheet)
      time_entry = create(:time_entry, user: other_user, timesheet: timesheet)
      create(:users_timesheet, user: other_user, timesheet: timesheet, role: 'user')

      delete :delete, params: { id: time_entry.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #popular' do
    it 'returns popular categories and projects for the user' do
      timesheet = create(:timesheet)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)

      get :popular

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #days' do
    it 'returns total hours by month day for the user' do
      timesheet = create(:timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :days, params: { month: '2023-09', timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #months' do
    it 'returns a list of time entries by month for the user' do
      timesheet = create(:timesheet)
      create(:time_entry, user: user, timesheet: timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :months, params: { timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #totals' do
    let(:timesheet) { create(:timesheet) }

    before do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
    end

    it 'returns totals for the selected month and the whole timesheet' do
      current_month = Date.current.strftime('%Y-%m')
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 2.5)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.current, decimal_time: 1.5)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: 2.months.ago, decimal_time: 8)

      get :totals, params: { month: current_month, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'total_hours_current_month' => 4.0,
        'total_hours_current_timesheet' => 12.0
      )
    end

    it 'returns a bad request when the timesheet does not exist' do
      get :totals, params: { month: Date.current.strftime('%Y-%m'), timesheet_uuid: 'missing' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized when the user cannot access the timesheet' do
      inaccessible_timesheet = create(:timesheet)

      get :totals, params: { month: Date.current.strftime('%Y-%m'), timesheet_uuid: inaccessible_timesheet.uuid }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not reuse a sudo selection from another timesheet' do
      first_timesheet = create(:timesheet)
      selected_user = create(:user)
      create(:users_timesheet, user: user, timesheet: first_timesheet, role: 'admin')
      create(:users_timesheet, user: selected_user, timesheet: first_timesheet, role: 'user')
      create(:users_timesheet, user: selected_user, timesheet: timesheet, role: 'user')
      selected_entry = create(
        :time_entry,
        user: selected_user,
        timesheet: timesheet,
        entry_date: Date.current,
        decimal_time: 8
      )
      session["#{user.id}_active_users"] = {
        'timesheet_id' => first_timesheet.id,
        'user_ids' => [selected_user.id]
      }

      get :entries, params: { timesheet_uuid: timesheet.uuid, month: 'all' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck('id')).not_to include(selected_entry.id)
      expect(session["#{user.id}_active_users"]).to be_nil
    end
  end

  describe 'GET #auto_complete' do
    it 'returns auto-complete suggestions for category or project' do
      timesheet = create(:timesheet, :with_fields)
      time_entry = create(:time_entry, user: user, timesheet: timesheet)

      get :auto_complete, params: { field: 'category', term: 'search_term', timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
    end

    it 'returns a bad request if field or term is missing' do
      get :auto_complete

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns a bad request if field is invalid' do
      get :auto_complete, params: { field: 'invalid_field', term: 'search_term' }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET #auto_complete values' do
    let(:timesheet) { create(:timesheet, :with_fields) }
    let(:project) { timesheet.custom_fields.find_by!(machine_name: 'project') }

    def add_value(value, owner: user, count: 1)
      create_list(:time_entry, count, user: owner, timesheet: timesheet).each do |entry|
        create(:custom_field_data_item, owner: entry, custom_field: project, value: value)
      end
    end

    it 'returns the matching values of the user, the most used first' do
      add_value('Apollo program')
      add_value('Apollo', count: 3)
      add_value('Gemini', count: 5)
      add_value('Apollo secret', owner: create(:user))

      get :auto_complete, params: { field: 'project', term: 'apo', timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(['Apollo', 'Apollo program'])
    end

    it 'returns at most five values' do
      7.times { |index| add_value("Apollo #{index}") }

      get :auto_complete, params: { field: 'project', term: 'apollo', timesheet_uuid: timesheet.uuid }

      expect(response.parsed_body.size).to eq(5)
    end

    it 'returns a bad request for a field of another timesheet' do
      add_value('Apollo')

      get :auto_complete, params: { field: 'project', term: 'apo', timesheet_uuid: create(:timesheet).uuid }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET #entries filters' do
    let(:timesheet) { create(:timesheet) }
    let(:member) { create(:user) }

    def add_entry(date, owner: user)
      create(:time_entry, user: owner, timesheet: timesheet, entry_date: date)
    end

    def entry_ids(params = {})
      get :entries, params: { timesheet_uuid: timesheet.uuid }.merge(params)
      expect(response).to have_http_status(:ok)
      response.parsed_body.pluck('id')
    end

    context 'as a regular member' do
      before do
        create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
        create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      end

      it 'returns the entries of the given month' do
        september = add_entry(Date.new(2026, 9, 10))
        add_entry(Date.new(2026, 10, 10))

        expect(entry_ids(month: '2026-09')).to eq([september.id])
      end

      it 'returns the entries between the period dates' do
        period = create(:period, timesheet: timesheet, from: Date.new(2026, 9, 1), to: Date.new(2026, 9, 30))
        inside = add_entry(Date.new(2026, 9, 30))
        add_entry(Date.new(2026, 10, 1))
        add_entry(Date.new(2026, 8, 31))

        expect(entry_ids(period: period.id)).to eq([inside.id])
      end

      it 'returns only the own entries' do
        own = add_entry(Date.new(2026, 9, 10))
        add_entry(Date.new(2026, 9, 10), owner: member)

        expect(entry_ids(month: 'all')).to eq([own.id])
      end

      it 'returns the own entries when asked for them' do
        own = add_entry(Date.new(2026, 9, 10))

        expect(entry_ids(month: 'all', user: user.id)).to eq([own.id])
      end

      %i[entries days months totals].each do |action|
        it "returns unauthorized from #{action} for the entries of another member" do
          add_entry(Date.new(2026, 9, 10), owner: member)

          get action, params: { timesheet_uuid: timesheet.uuid, month: '2026-09', user: member.id }

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body).to eq('message' => 'Unauthorized')
        end
      end

      it 'returns unauthorized from the CSV export for the entries of another member' do
        add_entry(Date.new(2026, 9, 10), owner: member)

        get :entries, params: { timesheet_uuid: timesheet.uuid, month: '2026-09', user: member.id, csv: true }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized for a user that does not exist' do
        get :entries, params: { timesheet_uuid: timesheet.uuid, month: 'all', user: 0 }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns the user email and the custom field values' do
        field = create(:custom_field, customizable: timesheet, machine_name: 'project')
        entry = add_entry(Date.new(2026, 9, 10))
        create(:custom_field_data_item, owner: entry, custom_field: field, value: 'Apollo')

        get :entries, params: { timesheet_uuid: timesheet.uuid, month: 'all' }

        expect(response.parsed_body.first).to include(
          'id' => entry.id,
          'email' => user.email,
          'entry_date' => '2026-09-10',
          'fields' => { 'project' => 'Apollo' }
        )
      end

      it 'ignores a sudo selection' do
        own = add_entry(Date.new(2026, 9, 10))
        add_entry(Date.new(2026, 9, 10), owner: member)
        session["#{user.id}_active_users"] = { 'timesheet_id' => timesheet.id, 'user_ids' => [member.id] }

        expect(entry_ids(month: 'all')).to eq([own.id])
        expect(session["#{user.id}_active_users"]).to be_nil
      end
    end

    context 'as an admin' do
      before do
        create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
        create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      end

      it 'returns the entries of a member' do
        add_entry(Date.new(2026, 9, 10))
        member_entry = add_entry(Date.new(2026, 9, 10), owner: member)

        expect(entry_ids(month: 'all', user: member.id)).to eq([member_entry.id])
      end

      it 'returns the entries of the users selected with sudo' do
        second_member = create(:user)
        create(:users_timesheet, user: second_member, timesheet: timesheet, role: 'user')
        add_entry(Date.new(2026, 9, 10))
        selected = [add_entry(Date.new(2026, 9, 10), owner: member), add_entry(Date.new(2026, 9, 11), owner: second_member)]
        session["#{user.id}_active_users"] = {
          'timesheet_id' => timesheet.id,
          'user_ids' => [member.id, second_member.id]
        }

        expect(entry_ids(month: 'all')).to match_array(selected.map(&:id))
      end

      it 'returns no entries when the selected sudo users left the timesheet' do
        unselected_member = create(:user)
        create(:users_timesheet, user: unselected_member, timesheet: timesheet, role: 'user')
        add_entry(Date.new(2026, 9, 10), owner: member)
        add_entry(Date.new(2026, 9, 11), owner: unselected_member)
        session["#{user.id}_active_users"] = {
          'timesheet_id' => timesheet.id,
          'user_ids' => [member.id]
        }
        UsersTimesheet.find_by!(user: member, timesheet: timesheet).destroy!

        expect(entry_ids(month: 'all')).to be_empty
      end
    end

    it 'lets a superadmin see the entries of any member' do
      sign_in create(:user, superadmin: true)
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      member_entry = add_entry(Date.new(2026, 9, 10), owner: member)

      expect(entry_ids(month: 'all', user: member.id)).to eq([member_entry.id])
    end

    it 'exports the entries of the month as CSV with a column for every field' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
      entry = create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.new(2026, 9, 10), decimal_time: 2.5)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.new(2026, 10, 10))
      create(:custom_field_data_item,
             owner: entry,
             custom_field: timesheet.custom_fields.find_by!(machine_name: 'project'),
             value: 'Apollo')

      get :entries, params: { timesheet_uuid: timesheet.uuid, csv: true, month: '2026-09' }

      header, *rows = CSV.parse(response.body)
      expect(header.first(3)).to eq(%w[username entry_date decimal_time])
      expect(header.drop(3)).to match_array(%w[category project description])
      expect(rows.size).to eq(1)
      expect(header.zip(rows.first).to_h).to include(
        'username' => user.email, 'entry_date' => '2026-09-10', 'project' => 'Apollo', 'category' => ''
      )
      expect(header.zip(rows.first).to_h['decimal_time'].to_d).to eq(2.5)
      expect(response.headers['Content-Disposition']).to include('time-entries-2026-09-')
    end
  end

  describe 'POST #edit changes' do
    let(:timesheet) { create(:timesheet, :with_fields) }
    let(:project) { timesheet.custom_fields.find_by!(machine_name: 'project') }

    before do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
    end

    it 'changes the hours and the date' do
      entry = create(:time_entry, user: user, timesheet: timesheet, decimal_time: 1, entry_date: Date.new(2026, 11, 2))

      post :edit, params: {
        timesheet_uuid: timesheet.uuid,
        time_entry: { id: entry.id, decimal_time: 3.75, entry_date: '2026-11-05' }
      }

      expect(response).to have_http_status(:ok)
      expect(entry.reload).to have_attributes(decimal_time: 3.75, entry_date: Date.new(2026, 11, 5))
      expect(response.parsed_body).to include('id' => entry.id, 'email' => user.email)
    end

    it 'can be sent with PATCH' do
      entry = create(:time_entry, user: user, timesheet: timesheet, decimal_time: 1)

      patch :edit, params: { timesheet_uuid: timesheet.uuid, time_entry: { id: entry.id, decimal_time: 2 } }

      expect(response).to have_http_status(:ok)
      expect(entry.reload.decimal_time).to eq(2)
    end

    it 'creates an entry of the current user for today with zero hours when not given' do
      post :edit, params: { timesheet_uuid: timesheet.uuid, time_entry: { fields: { project: 'Apollo' } } }

      expect(TimeEntry.last).to have_attributes(
        user_id: user.id,
        timesheet_id: timesheet.id,
        decimal_time: 0,
        entry_date: Date.current
      )
    end

    it 'removes a custom field value sent blank' do
      entry = create(:time_entry, user: user, timesheet: timesheet)
      create(:custom_field_data_item, owner: entry, custom_field: project, value: 'Apollo')

      post :edit, params: { timesheet_uuid: timesheet.uuid, time_entry: { id: entry.id, fields: { project: '' } } }

      expect(response).to have_http_status(:ok)
      expect(CustomFieldDataItem.where(owner: entry)).to be_empty
    end

    it 'skips the fields that the timesheet does not have' do
      other_field = create(:custom_field, customizable: create(:timesheet), machine_name: 'secret')

      post :edit, params: {
        timesheet_uuid: timesheet.uuid,
        time_entry: { fields: { secret: 'Hidden', project: 'Apollo' } }
      }

      expect(response.parsed_body['fields']).to eq('project' => 'Apollo')
      expect(other_field.custom_field_data_items).to be_empty
    end

    it 'does not let a user change an entry of another user' do
      other = create(:user)
      create(:users_timesheet, user: other, timesheet: timesheet, role: 'user')
      entry = create(:time_entry, user: other, timesheet: timesheet, decimal_time: 1)

      post :edit, params: {
        timesheet_uuid: timesheet.uuid,
        time_entry: { id: entry.id, decimal_time: 9, fields: { project: 'Changed' } }
      }

      expect(response).to have_http_status(:unauthorized)
      expect(entry.reload.decimal_time).to eq(1)
      expect(CustomFieldDataItem.where(owner: entry)).to be_empty
    end

    it 'lets a superadmin edit another user entry without changing its owner' do
      owner = create(:user)
      entry = create(:time_entry, user: owner, timesheet: timesheet, decimal_time: 1)
      sign_in create(:user, superadmin: true)

      post :edit, params: {
        timesheet_uuid: timesheet.uuid,
        time_entry: { id: entry.id, decimal_time: 4 }
      }

      expect(response).to have_http_status(:ok)
      expect(entry.reload).to have_attributes(user_id: owner.id, timesheet_id: timesheet.id, decimal_time: 4)
    end

    it 'does not move a persisted entry to another timesheet' do
      other_timesheet = create(:timesheet)
      entry = create(:time_entry, user: user, timesheet: timesheet, decimal_time: 1)
      sign_in create(:user, superadmin: true)

      post :edit, params: {
        timesheet_uuid: other_timesheet.uuid,
        time_entry: { id: entry.id, decimal_time: 4 }
      }

      expect(response).to have_http_status(:unauthorized)
      expect(entry.reload).to have_attributes(timesheet_id: timesheet.id, decimal_time: 1)
    end

    it 'returns a bad request for an entry without a date' do
      entry = create(:time_entry, user: user, timesheet: timesheet, entry_date: Date.new(2026, 11, 2))

      post :edit, params: { timesheet_uuid: timesheet.uuid, time_entry: { id: entry.id, entry_date: '' } }

      expect(response).to have_http_status(:bad_request)
      expect(entry.reload.entry_date).to eq(Date.new(2026, 11, 2))
    end

    it 'returns unauthorized when not signed in' do
      sign_out user

      post :edit, params: { timesheet_uuid: timesheet.uuid, time_entry: { decimal_time: 1 } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE #delete more' do
    it 'lets a superadmin delete an entry of any user' do
      entry = create(:time_entry)
      sign_in create(:user, superadmin: true)

      delete :delete, params: { id: entry.id }

      expect(response).to have_http_status(:ok)
      expect(TimeEntry.exists?(entry.id)).to be(false)
    end

    it 'removes the custom field values of the entry' do
      timesheet = create(:timesheet, :with_fields)
      entry = create(:time_entry, user: user, timesheet: timesheet)
      create(:custom_field_data_item, owner: entry, custom_field: timesheet.custom_fields.first)

      expect { delete :delete, params: { id: entry.id } }.to change(CustomFieldDataItem, :count).by(-1)
    end
  end

  describe 'GET #popular values' do
    it 'returns the popular values of the user' do
      timesheet = create(:timesheet)
      field = create(:custom_field, customizable: timesheet, machine_name: 'project', popular: true)
      entry = create(:time_entry, user: user, timesheet: timesheet)
      create(:custom_field_data_item, owner: entry, custom_field: field, value: 'Apollo')

      get :popular

      expect(response.parsed_body).to eq('project' => ['Apollo'])
    end
  end

  describe 'GET #days totals' do
    let(:timesheet) { create(:timesheet) }

    before do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
    end

    def add_entry(date, hours)
      create(:time_entry, user: user, timesheet: timesheet, entry_date: date, decimal_time: hours)
    end

    it 'returns the hours of every day of the month' do
      add_entry(Date.new(2026, 9, 10), 2)
      add_entry(Date.new(2026, 9, 10), 1)
      add_entry(Date.new(2026, 9, 11), 4)
      add_entry(Date.new(2026, 10, 1), 8)

      get :days, params: { month: '2026-09', timesheet_uuid: timesheet.uuid }

      expect(response.parsed_body).to eq([
        { 'date' => '2026-09-11', 'total_hours' => 4.0, 'email' => user.email },
        { 'date' => '2026-09-10', 'total_hours' => 3.0, 'email' => user.email }
      ])
    end

    it 'returns the hours of every week in weeks mode' do
      add_entry(Date.new(2026, 9, 9), 2) # Wednesday
      add_entry(Date.new(2026, 9, 10), 1)

      get :days, params: { month: '2026-09', mode: 'weeks', timesheet_uuid: timesheet.uuid }

      expect(response.parsed_body).to eq([{ 'date' => '2026-09-06', 'total_hours' => 3.0, 'email' => user.email }])
    end

    it 'returns the hours between the period dates' do
      period = create(:period, timesheet: timesheet, from: Date.new(2026, 9, 10), to: Date.new(2026, 10, 10))
      add_entry(Date.new(2026, 9, 9), 2)
      add_entry(Date.new(2026, 10, 10), 1)

      get :days, params: { period: period.id, timesheet_uuid: timesheet.uuid }

      expect(response.parsed_body).to eq([{ 'date' => '2026-10-10', 'total_hours' => 1.0, 'email' => user.email }])
    end

    it 'returns a bad request for a missing period' do
      get :days, params: { period: 0, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns a bad request for a missing timesheet' do
      get :days, params: { month: '2026-09', timesheet_uuid: 'missing' }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized for a timesheet of others' do
      get :days, params: { month: '2026-09', timesheet_uuid: create(:timesheet).uuid }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #months list' do
    let(:timesheet) { create(:timesheet) }

    before do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
      [Date.new(2026, 8, 31), Date.new(2026, 9, 10), Date.new(2026, 9, 20), Date.new(2026, 11, 1)].each do |date|
        create(:time_entry, user: user, timesheet: timesheet, entry_date: date)
      end
    end

    it 'returns the months with entries, the newest first' do
      get :months, params: { timesheet_uuid: timesheet.uuid }

      expect(response.parsed_body).to eq(%w[2026-11 2026-09 2026-08])
    end

    it 'returns the months between the period dates' do
      period = create(:period, timesheet: timesheet, from: Date.new(2026, 9, 1), to: Date.new(2026, 10, 31))

      get :months, params: { period: period.id, timesheet_uuid: timesheet.uuid }

      expect(response.parsed_body).to eq(['2026-09'])
    end

    it 'returns a bad request for a missing period' do
      get :months, params: { period: 0, timesheet_uuid: timesheet.uuid }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized for a timesheet of others' do
      get :months, params: { timesheet_uuid: create(:timesheet).uuid }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
