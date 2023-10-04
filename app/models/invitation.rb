class Invitation < ActiveRecord::Base
  VALID_ROLES = %w[admin user].freeze
  VALID_TYPES = %w[single multi].freeze

  belongs_to :timesheet
  belongs_to :sender, class_name: 'User'
  belongs_to :used_by, optional: true, class_name: 'User'

  validates :code, presence: true, uniqueness: true
  validates :sender, presence: true
  validates :itype, inclusion: { in: VALID_TYPES }
  validates :role, inclusion: { in: VALID_ROLES }

  attribute :used, :boolean, default: false
  attribute :itype, :string, default: 'single'
  attribute :role, :string, default: 'user'

  before_validation :generate_code, on: :create

  private

  def generate_code
    self.code = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Invitation.exists?(code: random_token)
    end
  end
end
