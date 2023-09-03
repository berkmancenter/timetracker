require 'securerandom'

class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :users_timesheets, dependent: :destroy
  has_many :timesheets, through: :users_timesheets

  if Rails.application.config.devise_auth_type == 'cas'
    devise :cas_authenticatable, :recoverable, :rememberable, :validatable
    before_validation :match_existing_user
  end

  if Rails.application.config.devise_auth_type == 'db'
    devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  end

  def user_timesheets
    timesheets
      .select('
        timesheets.id,
        timesheets.name,
        timesheets.uuid,
        ARRAY_AGG(users_timesheets.role) AS roles
      ')
      .group('timesheets.id')
  end

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
      when :mail
        self.email = value
      end
    end
  end

  private

  def match_existing_user
    existing_user = User.where(email: self.email).first

    unless existing_user.nil?
      self.id = existing_user.id
      self.password = existing_user.password
    end

    self.password = SecureRandom.base64(15) unless self.password.present?
  end
end
