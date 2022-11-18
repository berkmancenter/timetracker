class Credit < ActiveRecord::Base
  validates :amount, presence: true
  validates :user, presence: true
  validates :period, presence: true

  belongs_to :period
  belongs_to :user
end
