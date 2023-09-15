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
    category { Faker::Lorem.word }
    project { Faker::Lorem.word }
    decimal_time { Faker::Number.decimal(l_digits: 1, r_digits: 1) }
    description { Faker::Lorem.sentence }
    entry_date { Faker::Date.backward(days: 30) }
    timesheet
  end

  factory :timesheet do
    name { Faker::Lorem.word }
    public_code { Faker::Alphanumeric.alpha(number: 10) }
  end

  factory :user do
    username { Faker::Internet.unique.username(specifier: 10) }
    superadmin { false }
    email { Faker::Internet.unique.email }
    password { Devise.friendly_token(10) }
  end
end
