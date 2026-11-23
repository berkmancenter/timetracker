class Invitation < ApplicationRecord
  DEFAULT_EXPIRATION = 7.days
  VALID_ROLES = %w[admin user].freeze
  VALID_TYPES = %w[single multi].freeze

  belongs_to :timesheet
  belongs_to :sender, class_name: 'User'
  belongs_to :used_by, optional: true, class_name: 'User'

  validates :code, presence: true, uniqueness: true
  validates :email, presence: true, if: :single?
  validates :expiration, presence: true
  validates :sender, presence: true
  validates :itype, inclusion: { in: VALID_TYPES }
  validates :role, inclusion: { in: VALID_ROLES }

  attribute :used, :boolean, default: false
  attribute :itype, :string, default: 'single'
  attribute :role, :string, default: 'user'

  before_validation :prepare_for_creation, on: :create
  before_validation :normalize_email

  def redeemable_by?(user)
    return false if expiration.blank? || expiration <= Time.current
    return false if single? && used?
    return false if email.present? && email.casecmp?(user.email.to_s) == false

    true
  end

  def single?
    itype == 'single'
  end

  private

  def prepare_for_creation
    generate_code
    self.expiration ||= Time.current + DEFAULT_EXPIRATION
  end

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def generate_code
    return if code.present?

    self.code = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless Invitation.exists?(code: random_token)
    end
  end
end
