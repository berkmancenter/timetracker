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

  if Rails.application.config.devise_auth_type == 'saml'
    devise :saml_authenticatable, :rememberable
    before_validation :match_existing_user
  end

  if Rails.application.config.devise_auth_type == 'db'
    devise_modules = [:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable]
    devise_modules << :confirmable if ENV['DEVISE_CONFIRMABLE'] == 'true'
    devise(*devise_modules)
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
        timesheets.created_at,
        users_timesheets.timesheet_id,
        ARRAY_AGG(DISTINCT users_timesheets.role) AS roles
      ')
      .group('timesheets.id, users_timesheets.timesheet_id')
  end

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_s.downcase
      when 'mail'
        self.email = value
      when 'displayname'
        # Split displayName into first and last names
        name_parts = value.to_s.strip.split
        self.first_name = name_parts.first
        self.last_name = name_parts.last
      end
    end
  end

  def apply_saml_response(saml_response, auth_value)
    assign_external_attributes(
      email: saml_value(saml_response, :email) || auth_value,
      first_name: saml_value(saml_response, :first_name),
      last_name: saml_value(saml_response, :last_name),
      display_name: saml_value(saml_response, :display_name)
    )
  end

  def saml_extra_attributes=(extra_attributes)
    assign_external_attributes(
      email: external_attribute_value(extra_attributes, :email, :mail),
      first_name: external_attribute_value(extra_attributes, :first_name, :given_name, :givenName),
      last_name: external_attribute_value(extra_attributes, :last_name, :surname, :sn),
      display_name: external_attribute_value(extra_attributes, :display_name, :displayName, :name)
    )
  end

  def superadmin?
    superadmin
  end

  private

  def match_existing_user
    self.password = SecureRandom.base64(15) unless self.password.present?
  end

  def assign_external_attributes(email: nil, first_name: nil, last_name: nil, display_name: nil)
    self.email = email if email.present?
    self.first_name = first_name if first_name.present?
    self.last_name = last_name if last_name.present?
    assign_display_name(display_name)
  end

  def assign_display_name(display_name)
    return if display_name.blank? || (first_name.present? && last_name.present?)

    name_parts = display_name.to_s.strip.split
    self.first_name = name_parts.first if first_name.blank?
    self.last_name = name_parts.last if last_name.blank?
  end

  def saml_value(saml_response, key)
    normalize_external_value(saml_response.attribute_value_by_resource_key(key))
  end

  def external_attribute_value(attributes, *keys)
    keys.each do |key|
      value = normalize_external_value(attributes[key] || attributes[key.to_s])
      return value if value.present?
    end

    nil
  end

  def normalize_external_value(value)
    value = value.first if value.respond_to?(:first) && !value.is_a?(String)
    value.to_s.presence
  end

  def root_path
    new_user_session_path
  end
end
