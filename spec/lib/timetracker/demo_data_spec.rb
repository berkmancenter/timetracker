require 'rails_helper'

RSpec.describe Timetracker::DemoData do
  include ActiveSupport::Testing::TimeHelpers

  subject(:demo) { described_class.new(history_days: 30) }

  let(:maya) { User.find_by!(email: 'maya@demo.timetracker.test') }
  let(:sam) { User.find_by!(email: 'sam@demo.timetracker.test') }
  let(:lab) { Timesheet.find_by!(uuid: described_class.uuid_for('research-lab')) }

  it 'loads people, timesheets, periods and invitations' do
    demo.load!

    expect(demo.demo_users.count).to eq(8)
    expect(demo.demo_timesheets.pluck(:name)).to contain_exactly('Research Lab', 'Legal Clinic', 'Writing group')
    expect(User.find_by!(email: 'admin@demo.timetracker.test')).to be_superadmin
    expect(maya).to have_attributes(first_name: 'Maya', last_name: 'Chen')
    expect(maya.valid_password?(described_class::DEFAULT_PASSWORD)).to be(true)
    expect(lab.admin?(maya)).to be(true)
    expect(lab.users.map(&:email)).to contain_exactly(
      'maya@demo.timetracker.test', 'jonas@demo.timetracker.test',
      'priya@demo.timetracker.test', 'sam@demo.timetracker.test'
    )
    expect(lab.custom_fields.pluck(:machine_name, :input_type)).to eq(
      [%w[project text], %w[activity text], %w[notes long_text]]
    )
    expect(lab.periods.pluck(:name)).to contain_exactly('Last term', 'Current term', 'Next term')
    expect(Invitation.find_by!(code: 'demo-lab-lea')).to have_attributes(email: 'lea@demo.timetracker.test', used: false)
    expect(Invitation.find_by!(code: 'demo-writing-group')).to have_attributes(itype: 'multi', email: nil)
    expect(Invitation.find_by!(code: 'demo-lab-sam').used_by).to eq(sam)
  end

  it 'has invitations in every state' do
    demo.load!

    lea = User.find_by!(email: 'lea@demo.timetracker.test')
    tom = User.find_by!(email: 'tom@demo.timetracker.test')
    nora = User.find_by!(email: 'nora@demo.timetracker.test')

    expect(Invitation.find_by!(code: 'demo-lab-lea').redeemable_by?(lea)).to be(true)
    expect(Invitation.find_by!(code: 'demo-lab-lea').redeemable_by?(tom)).to be(false)
    expect(Invitation.find_by!(code: 'demo-lab-tom').redeemable_by?(tom)).to be(false)
    expect(Invitation.find_by!(code: 'demo-lab-sam').redeemable_by?(sam)).to be(false)
    expect(Invitation.find_by!(code: 'demo-writing-group').redeemable_by?(nora)).to be(true)
  end

  it 'generates entries on weekdays with field values' do
    demo.load!

    # The clinic has no written entries, only generated ones.
    clinic = Timesheet.find_by!(uuid: described_class.uuid_for('legal-clinic'))
    generated = TimeEntry.where(timesheet: clinic)
    expect(generated.count).to be > 20
    expect(generated.map(&:entry_date)).to all(satisfy(&:on_weekday?))
    expect(generated.minimum(:decimal_time)).to be >= 0.25
    expect(generated.minimum(:entry_date)).to be >= 30.days.ago.to_date
    expect(generated.maximum(:entry_date)).to be < Date.current
    expect(TimeEntry.where(user: sam, timesheet: lab).maximum(:entry_date)).to eq(11.days.ago.to_date)

    projects = CustomFieldDataItem.where(custom_field: lab.custom_fields.find_by!(machine_name: 'project'))
    expect(projects.distinct.pluck(:value)).to include('Platform governance', 'Lab admin')
    expect(TimeEntry.popular(maya)['project']).to be_present
  end

  it 'gives the current term balances a story' do
    described_class.new.load!

    stats = lab.periods.find_by!(name: 'Current term').get_stats.index_by { |row| row['email'] }
    expect(stats['priya@demo.timetracker.test']['balance'].to_d).to be_positive
    expect(stats['sam@demo.timetracker.test']['balance'].to_d).to be_negative
    expect(stats['sam@demo.timetracker.test'].values).to include('NSF grant', 'Maya Chen')
  end

  it 'gives the same data on every run' do
    demo.load!
    first_run = TimeEntry.order(:entry_date, :id).pluck(:entry_date, :decimal_time)

    described_class.new(history_days: 30).load!

    expect(TimeEntry.order(:entry_date, :id).pluck(:entry_date, :decimal_time)).to eq(first_run)
    expect(lab.uuid).to eq(described_class.uuid_for('research-lab'))
  end

  it 'puts the demo data back to its starting state when loaded again' do
    demo.load!
    lea = User.find_by!(email: 'lea@demo.timetracker.test')
    lab.update!(name: 'Renamed while playing')
    lab.custom_fields.create!(title: 'Added while playing', input_type: 'text')
    entry_count = TimeEntry.where(timesheet: lab).count
    TimeEntry.create!(user: maya, timesheet: lab, entry_date: Date.current, decimal_time: 8)
    UsersTimesheet.create!(user: lea, timesheet: lab, role: 'user')
    Invitation.find_by!(code: 'demo-lab-lea').update!(used: true, used_by: lea)
    lab.periods.create!(name: 'Current term clone', from: Date.current, to: Date.current)
    User.create!(email: 'rosa@demo.timetracker.test', password: 'signed-up-while-playing')

    demo.load!

    lab.reload
    expect(lab.name).to eq('Research Lab')
    expect(lab.custom_fields.pluck(:machine_name)).to eq(%w[project activity notes])
    expect(TimeEntry.where(timesheet: lab).count).to eq(entry_count)
    expect(lab.users).not_to include(lea)
    expect(Invitation.find_by!(code: 'demo-lab-lea')).to have_attributes(used: false, used_by: nil)
    expect(lab.periods.pluck(:name)).to contain_exactly('Last term', 'Current term', 'Next term')
    expect(User.exists?(email: 'rosa@demo.timetracker.test')).to be(false)
  end

  it 'never touches other data' do
    real_user = create(:user)
    real_timesheet = create(:timesheet)
    real_entry = create(:time_entry, user: real_user, timesheet: real_timesheet)
    create(:invitation, code: 'demo-lab-lea', timesheet: real_timesheet, sender: real_user, used_by: nil)

    demo.load!
    expect(demo.skipped_codes).to eq(['demo-lab-lea'])

    UsersTimesheet.create!(user: real_user, timesheet: lab, role: 'user')
    create(:time_entry, user: real_user, timesheet: lab)
    demo.load!
    expect(lab.users).to include(real_user)
    expect(TimeEntry.where(user: real_user, timesheet: lab).count).to eq(1)

    demo.remove!
    expect(User.all).to contain_exactly(real_user)
    expect(Timesheet.all).to contain_exactly(real_timesheet)
    expect(TimeEntry.all).to contain_exactly(real_entry)
    expect(Invitation.pluck(:code)).to eq(['demo-lab-lea'])
  end

  it 'removes demo users that sent invitations to other timesheets' do
    demo.load!
    real_timesheet = create(:timesheet)
    Invitation.create!(timesheet: real_timesheet, sender: maya, email: 'someone@example.org')

    demo.remove!

    expect(demo.demo_users).to be_empty
    expect(Invitation.where(timesheet: real_timesheet)).to be_empty
  end

  it 'goes back as many days as asked' do
    # Only generated entries there, the written ones have their own dates.
    clinic_entries = -> { TimeEntry.joins(:timesheet).where(timesheets: { name: 'Legal Clinic' }) }

    described_class.new(history_days: 10).load!
    expect(clinic_entries.call.minimum(:entry_date)).to be >= 10.days.ago.to_date

    described_class.new(history_days: 60).load!
    expect(clinic_entries.call.minimum(:entry_date)).to be < 30.days.ago.to_date
  end

  it 'reports the accounts, the password and links' do
    demo.load!

    expect(demo.report).to include(
      'maya@demo.timetracker.test', described_class::DEFAULT_PASSWORD, 'Things to try',
      "/#{lab.uuid}", "/admin/timesheets/#{lab.id}/periods/", '/join/demo-lab-lea'
    )
  end

  it 'reports when nothing is loaded' do
    expect(demo.report).to include('No demo data loaded')
  end

  it 'only loads in development and test unless allowed' do
    allow(Rails.env).to receive(:local?).and_return(false)

    expect { demo.load! }.to raise_error(described_class::NotAllowed)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ALLOW_DEMO_DATA').and_return('true')
    expect { demo.load! }.not_to raise_error
  end

  it 'understands the dates of the data file' do
    travel_to Time.zone.local(2026, 11, 20, 10) do
      expect(described_class.date('today')).to eq(Date.new(2026, 11, 20))
      expect(described_class.date('3 days ago')).to eq(Date.new(2026, 11, 17))
      expect(described_class.date('1 week ago')).to eq(Date.new(2026, 11, 13))
      expect(described_class.date('in 2 weeks')).to eq(Date.new(2026, 12, 4))
    end
    expect { described_class.date('yesterday') }.to raise_error(ArgumentError, /Unknown date/)
  end
end
