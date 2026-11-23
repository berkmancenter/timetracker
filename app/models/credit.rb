class Credit < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0, less_than: 10_000 }
  validates :user, presence: true
  validates :period, presence: true
  validates :user_id, uniqueness: { scope: :period_id }

  belongs_to :period
  belongs_to :user
end
