class User < ActiveRecord::Base
  devise :cas_authenticatable, :recoverable, :rememberable, :validatable
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :users_timesheets, dependent: :destroy
  has_many :timesheets, through: :users_timesheets

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
end
