require 'rails_helper'

RSpec.describe PeriodsController, type: :controller do
  let(:user) { create(:user) }
  let(:superadmin_user) { create(:user, superadmin: true) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a list of periods' do
      period = create_period

      get :index, params: { timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
      expect(JSON.parse(response.body).pluck('id')).to match_array([period.id])
    end

    it 'returns all periods for superadmin' do
      period1 = create_period(user)
      period2 = create_period(user)

      sign_out user
      sign_in superadmin_user

      get :index, params: { timesheet_id: period1.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).pluck('id')).to match_array([period1.id])

      get :index, params: { timesheet_id: period2.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).pluck('id')).to match_array([period2.id])
    end

    it 'does not expose periods to a non-admin account' do
      period = create(:period)

      get :index, params: { timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #show' do
    it 'returns a specific period' do
      period = create_period

      get :show, params: { id: period.id, timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(period.id)
    end

    it 'accepts the timesheet uuid used by tracker period routes' do
      period = create_period

      get :show, params: { id: period.id, timesheet_id: period.timesheet.uuid }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(period.id)
    end

    it 'returns unauthorized before looking up the period when not signed in' do
      timesheet = create(:timesheet)
      sign_out user

      get :show, params: { id: 0, timesheet_id: timesheet.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #upsert' do
    it 'creates a new period' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      post :upsert, params: { period: attributes_for(:period, timesheet_id: timesheet.id), timesheet_id: timesheet.id }
      post :upsert, params: { period: attributes_for(:period, timesheet_id: timesheet.id), timesheet_id: timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(Period.count).to eq(2)
    end

    it 'updates an existing period' do
      period = create_period
      new_name = 'Updated Period'
      post :upsert, params: { period: attributes_for(:period, id: period.id, name: new_name), timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(Period.find(period.id).name).to eq(new_name)
    end

    it 'returns a bad request if invalid data is provided' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      post :upsert, params: {
        period: attributes_for(:period, name: nil, timesheet_id: nil),
        timesheet_id: timesheet.id,
        id: nil
      }

      expect(response).to have_http_status(:bad_request)
    end

    it 'does not move a period from another timesheet before authorizing it' do
      victim_timesheet = create(:timesheet)
      victim_period = create(:period, timesheet: victim_timesheet, name: 'Victim period')
      credit = create(:credit, period: victim_period)
      attacker_timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: attacker_timesheet, role: 'admin')

      post :upsert, params: {
        timesheet_id: attacker_timesheet.id,
        period: attributes_for(
          :period,
          id: victim_period.id,
          timesheet_id: attacker_timesheet.id,
          name: 'Hijacked period'
        )
      }

      expect(response).to have_http_status(:bad_request)
      expect(victim_period.reload).to have_attributes(timesheet_id: victim_timesheet.id, name: 'Victim period')
      expect(credit.reload.period_id).to eq(victim_period.id)
    end

    it 'uses the nested timesheet instead of a body timesheet id' do
      timesheet = create(:timesheet)
      other_timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      post :upsert, params: {
        timesheet_id: timesheet.id,
        period: attributes_for(:period, timesheet_id: other_timesheet.id)
      }

      expect(response).to have_http_status(:ok)
      expect(Period.find(response.parsed_body.dig('period', 'id')).timesheet_id).to eq(timesheet.id)
    end
  end

  describe 'POST #delete' do
    it 'deletes selected periods' do
      period = create_period
      delete :delete, params: { periods: [period.id], timesheet_id: period.timesheet.id, id: period.id }

      expect(response).to have_http_status(:ok)
      expect(Period.count).to eq(0)
    end

    it 'returns a bad request if no periods are selected' do
      timesheet = create(:timesheet)
      delete :delete, params: { periods: [], timesheet_id: timesheet.id }

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET #credits' do
    it 'returns credits for the period' do
      period = create_period
      create(:credit, user: user, period: period)
      get :credits, params: { id: period.id, timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['credits']).to be_an(Array)
    end
  end

  describe 'POST #set_credits' do
    it 'sets credits for users in the period' do
      period = create_period
      post :set_credits, params: { id: period.id, timesheet_id: period.timesheet.id, credits: [{ user_id: user.id, credit_amount: 50.0 }] }

      expect(response).to have_http_status(:ok)
      expect(Credit.find_by(user: user, period: period).amount).to eq(50.0)
    end

    it 'returns a bad request if no users or credits are selected' do
      period = create_period
      post :set_credits, params: { id: period.id, credits: [], timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects period data for a user outside the timesheet' do
      period = create_period
      outsider = create(:user)
      field = create(:custom_field, customizable: period)

      expect do
        post :set_credits, params: {
          id: period.id,
          timesheet_id: period.timesheet.id,
          credits: [{
            user_id: outsider.id,
            credit_amount: 50,
            "custom_field_#{field.id}" => 'private'
          }]
        }
      end.not_to change { [Credit.count, CustomFieldDataItem.count] }

      expect(response).to have_http_status(:bad_request)
    end

    it 'rolls back credits when a custom field cannot be saved' do
      period = create_period
      field = create(:custom_field, customizable: period)
      invalid_item = build(:custom_field_data_item, custom_field: field, owner: user)
      invalid_item.errors.add(:value, 'is invalid')
      allow_any_instance_of(CustomFieldDataItem).to receive(:save!).and_raise(
        ActiveRecord::RecordInvalid.new(invalid_item)
      )

      expect do
        post :set_credits, params: {
          id: period.id,
          timesheet_id: period.timesheet.id,
          credits: [{
            user_id: user.id,
            credit_amount: 50,
            "custom_field_#{field.id}" => 'value'
          }]
        }
      end.not_to change(Credit, :count)

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'GET #stats' do
    it 'returns statistics for the period' do
      period = create_period
      get :stats, params: { id: period.id, timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('period')
      expect(JSON.parse(response.body)).to have_key('stats')
    end

    it 'returns statistics as CSV if csv param is present' do
      period = create_period
      field = create(:custom_field, customizable: period, title: 'Department')
      create(:credit, user: user, period: period, amount: 10)
      create(:custom_field_data_item, custom_field: field, owner: user, value: ' =1+1')
      get :stats, params: { id: period.id, csv: true, timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/octet-stream')
      expect(response.headers['Content-Disposition']).to match(/statistics/)
      expect(response.body).to include("' =1+1")
    end
  end

  describe 'POST #clone' do
    it 'clones the period' do
      period = create_period
      post :clone, params: { id: period.id, timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(Period.count).to eq(2)
    end

    it 'returns a bad request if cloning fails' do
      period = create_period
      allow_any_instance_of(Period).to receive(:save).and_return(false)

      post :clone, params: { id: period.id, timesheet_id: period.timesheet.id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'copies the dates, the credits and the custom fields' do
      period = create_period
      period.update!(name: 'Spring')
      create(:credit, user: user, period: period, amount: 10)
      create(:custom_field, customizable: period, machine_name: 'grant', title: 'Grant')

      post :clone, params: { id: period.id, timesheet_id: period.timesheet.id }

      cloned = Period.find(response.parsed_body['period']['id'])
      expect(cloned).to have_attributes(
        name: 'Spring clone',
        from: period.from,
        to: period.to,
        timesheet_id: period.timesheet_id
      )
      expect(cloned.credits.map { |credit| [credit.user_id, credit.amount] }).to eq([[user.id, 10]])
      expect(cloned.custom_fields.pluck(:title, :machine_name)).to eq([['Grant', "grant_clone_#{period.id}_0"]])
      expect(period.reload.credits.count).to eq(1)
      expect(period.custom_fields.count).to eq(1)
    end
  end

  describe 'access of a regular member' do
    let(:timesheet) { create(:timesheet) }
    let!(:period) { create(:period, timesheet: timesheet, name: 'Original') }
    let(:period_params) { { id: period.id, timesheet_id: timesheet.id } }

    before do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
    end

    it 'cannot list the periods' do
      get :index, params: { timesheet_id: timesheet.id }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot see the period' do
      get :show, params: period_params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot see the credits' do
      create(:credit, user: user, period: period)

      get :credits, params: period_params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot see the statistics, also as CSV' do
      get :stats, params: period_params
      expect(response).to have_http_status(:unauthorized)

      get :stats, params: period_params.merge(csv: true)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot create a period' do
      expect do
        post :upsert, params: { timesheet_id: timesheet.id, period: attributes_for(:period, timesheet_id: timesheet.id) }
      end.not_to change(Period, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot change the period' do
      post :upsert, params: { timesheet_id: timesheet.id, period: { id: period.id, name: 'Changed' } }

      expect(response).to have_http_status(:unauthorized)
      expect(period.reload.name).to eq('Original')
    end

    it 'cannot set credits' do
      expect do
        post :set_credits, params: period_params.merge(credits: [{ user_id: user.id, credit_amount: 10 }])
      end.not_to change(Credit, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot clone the period' do
      expect do
        post :clone, params: period_params
      end.not_to change(Period, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'cannot delete the period' do
      post :delete, params: { timesheet_id: timesheet.id, periods: [period.id] }

      expect(response).to have_http_status(:unauthorized)
      expect(Period.exists?(period.id)).to be(true)
    end
  end

  describe 'access of a superadmin' do
    let(:period) { create(:period) }

    before do
      sign_in superadmin_user
    end

    it 'can see and change a period of any timesheet' do
      get :show, params: { id: period.id, timesheet_id: period.timesheet_id }
      expect(response).to have_http_status(:ok)

      post :upsert, params: { timesheet_id: period.timesheet_id, period: { id: period.id, name: 'By superadmin' } }
      expect(response).to have_http_status(:ok)
      expect(period.reload.name).to eq('By superadmin')
    end

    it 'can delete a period of any timesheet' do
      post :delete, params: { timesheet_id: period.timesheet_id, periods: [period.id] }

      expect(response).to have_http_status(:ok)
      expect(Period.exists?(period.id)).to be(false)
    end
  end

  describe 'POST #delete of many periods' do
    it 'deletes nothing when one of the periods is in a timesheet of others' do
      own = create_period
      foreign = create(:period)

      post :delete, params: { timesheet_id: own.timesheet_id, periods: [own.id, foreign.id] }

      expect(response).to have_http_status(:unauthorized)
      expect(Period.where(id: [own.id, foreign.id]).count).to eq(2)
    end
  end

  describe 'GET #show details' do
    it 'returns the timesheet and the custom fields of the period' do
      period = create_period
      field = create(:custom_field, customizable: period, machine_name: 'grant', title: 'Grant')

      get :show, params: { id: period.id, timesheet_id: period.timesheet_id }

      expect(response.parsed_body).to include(
        'name' => period.name,
        'from' => period.from.as_json,
        'to' => period.to.as_json,
        'timesheet' => { 'id' => period.timesheet.id, 'name' => period.timesheet.name }
      )
      expect(response.parsed_body['custom_fields'].pluck('id', 'machine_name', 'title')).to eq(
        [[field.id, 'grant', 'Grant']]
      )
    end
  end

  describe 'POST #upsert details' do
    it 'returns the validation errors' do
      period = create_period

      post :upsert, params: {
        timesheet_id: period.timesheet_id,
        period: { id: period.id, from: '2026-11-10', to: '2026-11-01' }
      }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['message']).to eq('To must be on or after the start date')
    end

    it 'creates the period with its custom fields' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      post :upsert, params: {
        timesheet_id: timesheet.id,
        period: {
          name: 'Term',
          from: '2026-09-01',
          to: '2026-12-20',
          timesheet_id: timesheet.id,
          custom_fields_attributes: [{ title: 'Grant name', input_type: 'text', order: 1 }]
        }
      }

      expect(response).to have_http_status(:ok)
      period = Period.find(response.parsed_body['period']['id'])
      expect(period).to have_attributes(name: 'Term', from: Date.new(2026, 9, 1), to: Date.new(2026, 12, 20))
      expect(period.custom_fields.pluck(:machine_name)).to eq(['grant_name'])
      expect(response.parsed_body['period']['custom_fields'].pluck('title')).to eq(['Grant name'])
    end
  end

  describe 'GET #credits details' do
    it 'lists every member with the credit amount and the custom field values' do
      period = create_period
      member = create(:user, username: 'member', first_name: 'Ada', last_name: 'Lovelace')
      create(:users_timesheet, user: member, timesheet: period.timesheet, role: 'user')
      create(:credit, user: member, period: period, amount: 12.5)
      create(:credit, user: member, period: create(:period, timesheet: period.timesheet), amount: 99)
      field = create(:custom_field, customizable: period, machine_name: 'grant')
      create(:custom_field_data_item, custom_field: field, owner: member, value: 'NSF')

      get :credits, params: { id: period.id, timesheet_id: period.timesheet_id }

      credits = response.parsed_body['credits'].index_by { |row| row['user_id'] }
      expect(credits.keys).to contain_exactly(user.id, member.id)
      expect(credits[member.id]).to include(
        'username' => 'member',
        'email' => member.email,
        'first_name' => 'Ada',
        'last_name' => 'Lovelace',
        'admin' => false,
        'roles' => ['user'],
        "custom_field_#{field.id}" => 'NSF'
      )
      expect(credits[member.id]['credit_amount'].to_d).to eq(12.5)
      expect(credits[user.id]).to include('admin' => true, 'roles' => ['admin'])
      expect(credits[user.id]['credit_amount'].to_d).to eq(0)
    end
  end

  describe 'POST #set_credits details' do
    let(:period) { create_period }
    let(:member) { create(:user) }
    let(:params_base) { { id: period.id, timesheet_id: period.timesheet_id } }

    before do
      create(:users_timesheet, user: member, timesheet: period.timesheet, role: 'user')
    end

    it 'changes a credit and keeps the credits of other users' do
      create(:credit, user: user, period: period, amount: 10)
      create(:credit, user: member, period: period, amount: 30)

      post :set_credits, params: params_base.merge(credits: [{ user_id: user.id, credit_amount: 15 }])

      expect(response).to have_http_status(:ok)
      expect(period.credits.reload.map { |credit| [credit.user_id, credit.amount] }).to contain_exactly(
        [user.id, 15], [member.id, 30]
      )
    end

    it 'keeps one credit when the amount is the same' do
      create(:credit, user: user, period: period, amount: 10)

      post :set_credits, params: params_base.merge(credits: [{ user_id: user.id, credit_amount: '10.0' }])

      expect(Credit.where(period: period, user: user).pluck(:amount)).to eq([10])
    end

    it 'sets the credits of many users at once' do
      post :set_credits, params: params_base.merge(credits: [
        { user_id: user.id, credit_amount: 5 },
        { user_id: member.id, credit_amount: 7.5 }
      ])

      expect(period.credits.reload.map { |credit| [credit.user_id, credit.amount] }).to contain_exactly(
        [user.id, 5], [member.id, 7.5]
      )
    end

    it 'saves and changes the custom field values of the users' do
      field = create(:custom_field, customizable: period, machine_name: 'grant')

      post :set_credits, params: params_base.merge(credits: [
        { user_id: member.id, credit_amount: 5, "custom_field_#{field.id}" => 'NSF' }
      ])
      post :set_credits, params: params_base.merge(credits: [
        { user_id: member.id, credit_amount: 5, "custom_field_#{field.id}" => 'DARPA' }
      ])

      expect(CustomFieldDataItem.where(custom_field: field, owner: member).pluck(:value)).to eq(['DARPA'])
    end

    it 'saves custom field values without a credit amount' do
      field = create(:custom_field, customizable: period, machine_name: 'grant')

      post :set_credits, params: params_base.merge(credits: [
        { user_id: member.id, credit_amount: '', "custom_field_#{field.id}" => 'NSF' }
      ])

      expect(response).to have_http_status(:ok)
      expect(Credit.where(period: period)).to be_empty
      expect(CustomFieldDataItem.find_by!(custom_field: field, owner: member).value).to eq('NSF')
    end
  end

  describe 'GET #stats details' do
    let(:period) { create_period }
    let(:member) { create(:user) }

    before do
      create(:users_timesheet, user: member, timesheet: period.timesheet, role: 'user')
      create(:credit, user: user, period: period, amount: 10)
      create(:credit, user: member, period: period, amount: 20)
    end

    it 'returns the statistics of the selected users only' do
      get :stats, params: { id: period.id, timesheet_id: period.timesheet_id, user_ids: member.id.to_s }

      expect(response.parsed_body['stats'].pluck('user_id')).to eq([member.id])
      expect(response.parsed_body['period']['id']).to eq(period.id)
    end

    it 'names the CSV columns, custom fields by their title' do
      field = create(:custom_field, customizable: period, title: 'Grant')
      create(:custom_field_data_item, custom_field: field, owner: member, value: 'NSF')

      get :stats, params: { id: period.id, timesheet_id: period.timesheet_id, csv: true, user_ids: member.id.to_s }

      rows = CSV.parse(response.body)
      expect(rows.first).to eq(%w[username email credits total_hours should_hours balance balance_percent Grant])
      expect(rows.second.values_at(0, 1, 2, 7)).to eq([member.username, member.email, '20.00', 'NSF'])
      expect(rows.size).to eq(2)
      expect(response.headers['Content-Disposition']).to include("#{period.name.parameterize}-statistics-")
    end
  end

  private

  def create_period(puser = user)
    timesheet = create(:timesheet)
    create(:users_timesheet, user: puser, timesheet: timesheet, role: 'admin')
    create(:period, timesheet: timesheet)
  end
end
