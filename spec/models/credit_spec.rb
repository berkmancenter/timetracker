# spec/models/credit_spec.rb

require 'rails_helper'

RSpec.describe Credit, type: :model do
  # Ensure that a Credit record is valid with all required fields
  it 'is valid with valid attributes' do
    credit = build(:credit)
    expect(credit).to be_valid
  end

  # Validate presence of amount
  it 'is not valid without an amount' do
    credit = build(:credit, amount: nil)
    expect(credit).not_to be_valid
  end

  # Validate presence of user
  it 'is not valid without a user' do
    credit = build(:credit, user: nil)
    expect(credit).not_to be_valid
  end

  # Validate presence of period
  it 'is not valid without a period' do
    credit = build(:credit, period: nil)
    expect(credit).not_to be_valid
  end

  # Test associations

  it 'belongs to a user' do
    user = create(:user)
    credit = create(:credit, user: user)
    expect(credit.user).to eq(user)
  end

  it 'belongs to a period' do
    period = create(:period)
    credit = create(:credit, period: period)
    expect(credit.period).to eq(period)
  end
end
