require 'securerandom'

class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :users_timesheets, dependent: :destroy
  has_many :timesheets, through: :users_timesheets

  if Rails.application.config.devise_auth_type == 'cas'
    devise :cas_authenticatable, :rememberable
    before_validation :match_existing_user
  end

  if Rails.application.config.devise_auth_type == 'db'
    devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  end

  def user_timesheets(only_admin: false)
    all_user_timesheets = self.timesheets
    all_user_timesheets = all_user_timesheets.where("users_timesheets.role = 'admin'") if only_admin
    all_user_timesheets = UsersTimesheet.joins(:timesheet).group('timesheets.id').all if self.superadmin?

    all_user_timesheets
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

  def superadmin?
    superadmin
  end

  private

  def match_existing_user
    existing_user = User.where(email: self.email).first

    unless existing_user.nil?
      self.attributes = existing_user.attributes.except('username')
      @new_record = false
    end

    self.password = SecureRandom.base64(15) unless self.password.present?
  end
end
