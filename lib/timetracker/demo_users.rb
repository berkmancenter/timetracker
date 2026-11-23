module Timetracker
  # The people of the demo data (see Timetracker::DemoData).
  class DemoUsers
    def initialize(users_data, password:)
      @users_data = users_data
      @password = password
    end

    # Creates or restores every demo user, returns them by key (:maya, ...).
    def load
      @users_data.to_h do |attributes|
        first_name, last_name = attributes[:name].split(' ', 2)
        user = User.find_or_initialize_by(email: DemoData.email_for(attributes[:key]))
        user.first_name = first_name
        user.last_name = last_name
        user.superadmin = attributes.fetch(:superadmin, false)
        assign_password(user)
        user.skip_confirmation! if devise_module?(:confirmable) && !user.confirmed?
        user.save!
        [attributes[:key].to_sym, user]
      end
    end

    private

    # Other auth types (CAS, SAML, headers) have no passwords, their users are
    # matched by email when they log in.
    def assign_password(user)
      return unless devise_module?(:database_authenticatable)

      user.password = @password
      user.password_confirmation = @password
    end

    def devise_module?(name)
      User.devise_modules.include?(name)
    end
  end
end
