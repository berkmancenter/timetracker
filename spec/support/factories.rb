FactoryBot.define do
  factory :credit do
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 1) }
    user
    period
  end

  factory :invitation do
    code { Faker::Lorem.word }
    email { Faker::Internet.email }
    expiration { Faker::Time.forward(days: 30) }
    used { false }
    timesheet
    sender { build(:user) }
    used_by { build(:user) }
    itype { "single" }

    trait :single do
      itype { "single" }
    end

    trait :other_type do
      itype { "other_type" }
    end
  end

  factory :period do
    name { Faker::Lorem.word }
    from { Faker::Date.backward(days: 30) }
    to { Faker::Date.forward(days: 30) }
    timesheet
  end

  factory :time_entry do
    user
    decimal_time { Faker::Number.decimal(l_digits: 1, r_digits: 1) }
    entry_date { Faker::Date.backward(days: 30) }
    timesheet
  end

  factory :timesheet do
    name { Faker::Lorem.word }
    public_code { Faker::Alphanumeric.alpha(number: 10) }

    trait :with_fields do
      after(:build) do |timesheet|
        timesheet.custom_fields << build(:custom_field, :category, customizable: timesheet)
        timesheet.custom_fields << build(:custom_field, :project, customizable: timesheet)
        timesheet.custom_fields << build(:custom_field, :description, customizable: timesheet)
      end
    end
  end

  factory :custom_field do
    customizable { nil }
    input_type { 'text' }
    machine_name { Faker::Lorem.word }
    title { Faker::Lorem.word }
    order { 1 }
    description { Faker::Lorem.sentence }
    metadata { {} }
    popular { false }
    list { false }
    required { false }
    access_key { nil }

    trait :category do
      machine_name { 'category' }
      title { 'Category' }
      list { true }
    end

    trait :project do
      machine_name { 'project' }
      title { 'Project' }
      list { true }
    end

    trait :description do
      machine_name { 'description' }
      title { 'Description' }
    end
  end

  factory :custom_field_data_item do
    association :time_entry
    association :custom_field, factory: :custom_field
    value { Faker::Lorem.word }
  end

  factory :user do
    username { Faker::Internet.unique.username(specifier: 10) }
    superadmin { false }
    email { Faker::Internet.unique.email }
    password { Devise.friendly_token(10) }
  end

  factory :users_timesheet do
    association :user
    association :timesheet
    role { 'user' }
  end
end
