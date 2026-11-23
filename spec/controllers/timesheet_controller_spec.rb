require 'rails_helper'

RSpec.describe TimesheetsController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a list of user timesheets' do
      timesheet1 = create(:timesheet, name: 'Timesheet 1')
      timesheet2 = create(:timesheet, name: 'Timesheet 2')
      create(:users_timesheet, user: user, timesheet: timesheet1, role: 'admin')
      create(:users_timesheet, user: user, timesheet: timesheet2, role: 'user')

      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to match_array([
        { 'id' => timesheet1.id, 'name' => 'Timesheet 1', 'uuid' => timesheet1.uuid, 'roles' => ['admin'], 'created_at' => timesheet1.created_at.as_json, 'custom_fields' => [] },
        { 'id' => timesheet2.id, 'name' => 'Timesheet 2', 'uuid' => timesheet2.uuid, 'roles' => ['user'], 'created_at' => timesheet2.created_at.as_json, 'custom_fields' => [] }
      ])
    end

    it 'returns an empty list when the user has no timesheets' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns unauthorized when the user is not signed in' do
      sign_out user

      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end

    describe 'POST #upsert' do
    it 'creates a new timesheet' do
      expect do
        post :upsert, params: {
          timesheet: {
            name: 'New Timesheet',
            custom_fields_attributes: [
              {
                title: 'Category',
                input_type: 'text'
              }
            ]
          }
        }
      end.to change(Timesheet, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['timesheet']['name']).to eq('New Timesheet')
    end

    it 'updates an existing timesheet' do
      existing_timesheet = create(:timesheet, :with_fields, name: 'Existing Timesheet')
      create(:users_timesheet, user: user, timesheet: existing_timesheet, role: 'admin')

      post :upsert, params: {
        timesheet: {
          id: existing_timesheet.id,
          name: 'Updated Timesheet',
          custom_fields_attributes: [
            {
              title: 'Category 123',
              input_type: 'text'
            }
          ]
        }
      }

      existing_timesheet.reload
      expect(existing_timesheet.name).to eq('Updated Timesheet')
      expect(response).to have_http_status(:ok)
    end

    it 'returns a bad request if there are validation errors' do
      post :upsert, params: { timesheet: { name: nil } }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['message']).to include('Timesheet must have at least one field')
    end
  end

  describe 'DELETE #delete' do
    it 'deletes timesheets' do
      timesheet1 = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet1, role: 'admin')
      timesheet2 = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet2, role: 'admin')

      delete :delete, params: { timesheets: [timesheet1.id, timesheet2.id] }

      expect(response).to have_http_status(:ok)
      expect(Timesheet.where(id: [timesheet1.id, timesheet2.id])).to be_empty
    end

    it 'returns a bad request if the user is not authorized' do
      timesheet = create(:timesheet)
      sign_in create(:user)

      delete :delete, params: { timesheets: [timesheet.id] }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #send_invitations' do
    it 'sends invitations to specified emails with a valid role' do
      timesheet = create(:timesheet, name: 'Test Timesheet')
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      emails = 'test1@example.com, test2@example.com'
      emails_arr = ['test1@example.com', 'test2@example.com']
      valid_role = Invitation::VALID_ROLES.sample

      expect do
        post :send_invitations, params: { id: timesheet.id, emails: emails, role: valid_role }, format: :json
      end.to change(Invitation, :count).by(2)

      expect(response).to have_http_status(:ok)
      expect(Invitation.pluck(:email)).to match_array(emails_arr)
    end

    it 'returns unprocessable entity if no valid role is provided' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      emails = 'test1@example.com, test2@example.com'

      post :send_invitations, params: { id: timesheet.id, emails: emails, role: 'invalid_role' }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unauthorized if the user is not an admin' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')
      emails = 'test1@example.com, test2@example.com'

      post :send_invitations, params: { id: timesheet.id, emails: emails }, format: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #join' do
    it 'allows a user to join a timesheet using a valid invitation code' do
      invitation = create(:invitation, email: user.email, used: false)

      post :join, params: { code: invitation.code }, format: :json

      invitation.reload
      expect(invitation.used).to be(true)
      expect(response).to have_http_status(:ok)
    end

    it 'rejects an invitation issued to another email address' do
      invitation = create(:invitation, email: 'someone-else@example.com', used: false)

      expect do
        post :join, params: { code: invitation.code }, format: :json
      end.not_to change(UsersTimesheet, :count)

      expect(response).to have_http_status(:bad_request)
      expect(invitation.reload.used).to be(false)
    end

    it 'rejects an expired invitation' do
      invitation = create(:invitation, email: user.email, expiration: 1.minute.ago, used: false)

      post :join, params: { code: invitation.code }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(invitation.reload.used).to be(false)
    end

    it 'rolls back membership creation when invitation consumption fails' do
      invitation = create(:invitation, email: user.email, used: false)
      allow_any_instance_of(Invitation).to receive(:update!).and_raise(
        ActiveRecord::RecordInvalid.new(invitation)
      )

      expect do
        post :join, params: { code: invitation.code }, format: :json
      end.not_to change(UsersTimesheet, :count)

      expect(response).to have_http_status(:bad_request)
      expect(invitation.reload.used).to be(false)
    end

    it 'returns bad request for an invalid invitation code' do
      post :join, params: { code: 'invalid_code' }, format: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'DELETE #leave' do
    it 'allows a user to leave a timesheet' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet)

      delete :leave, params: { id: timesheet.id }, format: :json

      expect(UsersTimesheet.where(user: user, timesheet: timesheet)).to be_empty
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #users' do
    let(:timesheet) { create(:timesheet) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'returns users for the timesheet for the admin user' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user3, timesheet: timesheet, role: 'user')

      get :users, params: { id: timesheet.id }

      expect(response).to have_http_status(:ok)
      response_parsed = JSON.parse(response.body)
      expect(response_parsed).to be_an(Array)
      expect(response_parsed.pluck('id')).to eq([user.id, user1.id, user2.id, user3.id])
    end

    it 'returns a bad request for non-admin user' do
      get :users, params: { id: timesheet.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #delete_users' do
    let(:timesheet) { create(:timesheet) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    it 'deletes selected users from the timesheet for the admin user' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: user3, timesheet: timesheet, role: 'user')

      post :delete_users, params: { id: timesheet.id, users: [user1.id, user2.id] }

      expect(response).to have_http_status(:ok)
      expect(User.where(id: timesheet.users.pluck(:id))).to eq(User.where(id: [user.id, user3.id]))
    end

    it 'returns a bad request if no users are selected' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      post :delete_users, params: { id: timesheet.id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'returns unauthorized for non-admin user' do
      sign_out user
      sign_in user1

      post :delete_users, params: { id: timesheet.id, users: [user.id] }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #change_users_role' do
    let(:user) { create(:user) }
    let(:timesheet) { create(:timesheet) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      sign_in user
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user1, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: user2, timesheet: timesheet, role: 'admin')
    end

    it 'changes users roles for the admin user' do
      user_ids = [user2.id]

      post :change_users_role, params: { id: timesheet.id, users: user_ids, role: 'user' }, format: :json

      expect(response).to have_http_status(:ok)
      expect(UsersTimesheet.where(user_id: user_ids, timesheet: timesheet).pluck(:role)).to eq(['user'])
    end

    it 'returns bad request if no users are selected' do
      post :change_users_role, params: { id: timesheet.id, role: 'user' }, format: :json

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects an invalid role' do
      post :change_users_role,
           params: { id: timesheet.id, users: [user2.id], role: 'owner' },
           format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(UsersTimesheet.find_by!(timesheet: timesheet, user: user2).role).to eq('admin')
    end

    it 'returns unauthorized for non-admin user' do
      regular_user = create(:user)
      create(:users_timesheet, user: regular_user, timesheet: timesheet, role: 'user')

      sign_out user
      sign_in regular_user

      post :change_users_role, params: { id: timesheet.id, users: [user2.id], role: 'user' }, format: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'changes the role only in this timesheet' do
      other_timesheet = create(:timesheet)
      create(:users_timesheet, user: user2, timesheet: other_timesheet, role: 'admin')

      post :change_users_role, params: { id: timesheet.id, users: [user2.id], role: 'user' }, format: :json

      expect(UsersTimesheet.find_by!(timesheet: timesheet, user: user2).role).to eq('user')
      expect(UsersTimesheet.find_by!(timesheet: other_timesheet, user: user2).role).to eq('admin')
    end

    it 'can make a member an admin' do
      member = create(:user)
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')

      post :change_users_role, params: { id: timesheet.id, users: [member.id], role: 'admin' }, format: :json

      expect(response).to have_http_status(:ok)
      expect(timesheet.admin?(member)).to be(true)
    end
  end

  describe 'GET #index_admin' do
    it 'returns only the timesheets the user is admin of, with their fields' do
      admin_timesheet = create(:timesheet, :with_fields, name: 'Admin timesheet')
      member_timesheet = create(:timesheet, name: 'Member timesheet')
      create(:users_timesheet, user: user, timesheet: admin_timesheet, role: 'admin')
      create(:users_timesheet, user: user, timesheet: member_timesheet, role: 'user')

      get :index_admin

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck('name')).to eq(['Admin timesheet'])
      expect(response.parsed_body.first['custom_fields'].pluck('machine_name')).to match_array(
        %w[category project description]
      )
    end

    it 'returns unauthorized when not signed in' do
      sign_out user

      get :index_admin

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET #show' do
    let(:timesheet) { create(:timesheet, :with_fields, name: 'Shown timesheet') }

    it 'returns the timesheet with its fields to an admin' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      get :show, params: { id: timesheet.id }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('id' => timesheet.id, 'name' => 'Shown timesheet', 'uuid' => timesheet.uuid)
      expect(response.parsed_body['custom_fields'].pluck('machine_name')).to match_array(%w[category project description])
    end

    it 'returns the timesheet to a superadmin' do
      sign_in create(:user, superadmin: true)

      get :show, params: { id: timesheet.id }

      expect(response).to have_http_status(:ok)
    end

    it 'returns unauthorized to a regular member' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :show, params: { id: timesheet.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #upsert changes' do
    let(:field_params) { [{ title: 'Project', input_type: 'text' }] }

    it 'makes the creator an admin of the new timesheet' do
      post :upsert, params: { timesheet: { name: 'Mine', custom_fields_attributes: field_params } }

      timesheet = Timesheet.find(response.parsed_body['timesheet']['id'])
      expect(timesheet.admin?(user)).to be(true)
      expect(timesheet.custom_fields.pluck(:machine_name)).to eq(['project'])
    end

    it 'does not add a membership when updating' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      field = timesheet.custom_fields.first

      expect do
        post :upsert, params: {
          timesheet: { id: timesheet.id, name: 'Renamed', custom_fields_attributes: [{ id: field.id, title: 'Kept' }] }
        }
      end.not_to change(UsersTimesheet, :count)

      expect(response).to have_http_status(:ok)
      expect(field.reload.title).to eq('Kept')
    end

    it 'does not let a regular member change the timesheet' do
      timesheet = create(:timesheet, :with_fields, name: 'Original')
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      post :upsert, params: { timesheet: { id: timesheet.id, name: 'Changed', custom_fields_attributes: field_params } }

      expect(response).to have_http_status(:unauthorized)
      expect(timesheet.reload.name).to eq('Original')
      expect(timesheet.custom_fields.count).to eq(3)
    end

    it 'removes the fields marked to destroy' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      removed, kept, = timesheet.custom_fields.to_a

      post :upsert, params: {
        timesheet: {
          id: timesheet.id,
          name: timesheet.name,
          custom_fields_attributes: [{ id: removed.id, _destroy: 'true' }, { id: kept.id, title: kept.title }]
        }
      }

      expect(response).to have_http_status(:ok)
      expect(timesheet.custom_fields.reload).not_to include(removed)
      expect(timesheet.custom_fields.count).to eq(2)
    end

    it 'refuses to remove every field' do
      timesheet = create(:timesheet, :with_fields)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      post :upsert, params: {
        timesheet: {
          id: timesheet.id,
          name: timesheet.name,
          custom_fields_attributes: timesheet.custom_fields.map { |field| { id: field.id, _destroy: 'true' } }
        }
      }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['message']).to eq('Timesheet must have at least one field')
      expect(timesheet.custom_fields.count).to eq(3)
    end

    it 'returns the validation errors and creates nothing' do
      expect do
        post :upsert, params: { timesheet: { name: '', custom_fields_attributes: field_params } }
      end.not_to change { [Timesheet.count, UsersTimesheet.count] }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['message']).to include("Name can't be blank")
    end
  end

  describe 'POST #delete access' do
    it 'deletes nothing when one of the timesheets is not managed by the user' do
      own = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: own, role: 'admin')
      foreign = create(:timesheet)

      post :delete, params: { timesheets: [own.id, foreign.id] }

      expect(response).to have_http_status(:unauthorized)
      expect(Timesheet.where(id: [own.id, foreign.id]).count).to eq(2)
    end

    it 'does not let a regular member delete the timesheet' do
      timesheet = create(:timesheet)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      post :delete, params: { timesheets: [timesheet.id] }

      expect(response).to have_http_status(:unauthorized)
      expect(Timesheet.exists?(timesheet.id)).to be(true)
    end

    it 'lets a superadmin delete any timesheet' do
      timesheet = create(:timesheet)
      sign_in create(:user, superadmin: true)

      post :delete, params: { timesheets: [timesheet.id] }

      expect(response).to have_http_status(:ok)
      expect(Timesheet.exists?(timesheet.id)).to be(false)
    end
  end

  describe 'POST #send_invitations mails' do
    let(:timesheet) { create(:timesheet) }

    before do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
    end

    it 'sends a mail for every invitation' do
      expect do
        post :send_invitations, params: { id: timesheet.id, emails: 'a@example.com b@example.com', role: 'user' }
      end.to have_enqueued_mail(InvitationMailer, :send_invitation).twice
    end

    it 'reads the emails from any text and saves the role and the sender' do
      emails = "first@example.com;\nSecond@Example.com, not-an-email, third@example.org"

      post :send_invitations, params: { id: timesheet.id, emails: emails, role: 'admin' }

      expect(response).to have_http_status(:ok)
      expect(Invitation.where(timesheet: timesheet).pluck(:email, :role, :sender_id)).to contain_exactly(
        ['first@example.com', 'admin', user.id],
        ['second@example.com', 'admin', user.id],
        ['third@example.org', 'admin', user.id]
      )
    end

    it 'creates single invitations with a code and an expiration' do
      post :send_invitations, params: { id: timesheet.id, emails: 'a@example.com', role: 'user' }

      invitation = Invitation.find_by!(email: 'a@example.com')
      expect(invitation).to have_attributes(itype: 'single', used: false)
      expect(invitation.code).to be_present
      expect(invitation.expiration).to be > Time.current
    end
  end

  describe 'POST #join results' do
    it 'adds the user with the invitation role and returns the timesheet' do
      invitation = create(:invitation, email: user.email, role: 'admin', used_by: nil)

      post :join, params: { code: invitation.code }, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['timesheet']['id']).to eq(invitation.timesheet_id)
      expect(invitation.timesheet.admin?(user)).to be(true)
      expect(invitation.reload.used_by).to eq(user)
    end

    it 'keeps a multi invitation open for more users' do
      invitation = create(:invitation, itype: 'multi', email: nil, used_by: nil)
      second_user = create(:user)

      post :join, params: { code: invitation.code }, format: :json
      expect(response).to have_http_status(:ok)

      sign_in second_user
      post :join, params: { code: invitation.code }, format: :json
      expect(response).to have_http_status(:ok)

      expect(invitation.timesheet.users).to contain_exactly(user, second_user)
      expect(invitation.reload).to have_attributes(used: false, used_by: nil)
    end

    it 'rejects a single invitation that was used already' do
      invitation = create(:invitation, email: user.email, used: true)

      expect do
        post :join, params: { code: invitation.code }, format: :json
      end.not_to change(UsersTimesheet, :count)

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects a user who is a member already and keeps the invitation' do
      invitation = create(:invitation, email: user.email, used_by: nil)
      create(:users_timesheet, user: user, timesheet: invitation.timesheet, role: 'user')

      post :join, params: { code: invitation.code }, format: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['message']).to eq('Timesheet has already been taken')
      expect(invitation.reload.used).to be(false)
    end
  end

  describe 'DELETE #leave of one user' do
    it 'removes only the membership of the current user' do
      timesheet = create(:timesheet)
      other = create(:user)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: other, timesheet: timesheet, role: 'user')

      delete :leave, params: { id: timesheet.id }, format: :json

      expect(timesheet.users.reload).to eq([other])
    end
  end

  describe 'GET #user' do
    let(:timesheet) { create(:timesheet) }
    let(:member) { create(:user, first_name: 'Ada', last_name: 'Lovelace') }

    before do
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
    end

    it 'returns a member to an admin' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')

      get :user, params: { id: timesheet.id, user_id: member.id }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'id' => member.id, 'email' => member.email, 'first_name' => 'Ada', 'last_name' => 'Lovelace'
      )
    end

    it 'returns unauthorized to a regular member' do
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'user')

      get :user, params: { id: timesheet.id, user_id: member.id }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #delete_users in one timesheet' do
    it 'keeps the users in their other timesheets' do
      timesheet = create(:timesheet)
      other_timesheet = create(:timesheet)
      member = create(:user)
      create(:users_timesheet, user: user, timesheet: timesheet, role: 'admin')
      create(:users_timesheet, user: member, timesheet: timesheet, role: 'user')
      create(:users_timesheet, user: member, timesheet: other_timesheet, role: 'user')

      post :delete_users, params: { id: timesheet.id, users: [member.id] }

      expect(timesheet.users.reload).to eq([user])
      expect(other_timesheet.users.reload).to eq([member])
      expect(User.exists?(member.id)).to be(true)
    end
  end
end
