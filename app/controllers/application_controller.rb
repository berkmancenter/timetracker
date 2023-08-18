class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate
  skip_before_action :verify_authenticity_token

  layout 'regular'

  def ping
    render plain: 'pong'
  end

  protected

  def render_csv(param)
    param[:filebase] = param[:filebase].blank? ? param[:model].to_s.tableize : param[:filebase]
    param[:columns] = param[:model].columns.collect(&:name) if param[:columns].blank?

    csv_string = CSV.generate do |csv|
      csv << param[:columns]
      param[:objects].each do |record|
        line = param[:columns].collect { |col| record[col].to_s.chomp }
        csv << line
      end
    end

    send_data(
      csv_string,
      type: 'application/octet-stream',
      filename: "#{param[:filebase]}-#{Time.now.to_s(:number)}.csv"
    )
  end

  def authenticate
    use_fake_auth and return if Rails.application.config.use_fakeauth

    cas_data_file = "#{ENV['CAS_DATA_DIRECTORY']}/#{cookies[:MOD_AUTH_CAS]}"
    user_data = {}
    tries = 5

    begin
      # CAS data files are periodically refreshed and rewritten by the Apache
      # module, we don't want to end up reading them in the middle of this
      # operation.
      (1..tries).to_a.each do
        cas_data_file_content = File.read(cas_data_file)
        cas_data_file_parsed = Nokogiri::XML('<?xml version="1.0" encoding="utf-8"?>' + cas_data_file_content)
        cas_data_file_parsed.root.add_namespace_definition('def', 'http://uconn.edu/cas/mod_auth_cas')

        cas_data_file_parsed.search('//def:attribute').each do |attribute|
          if attribute.attributes['name'].value == 'mail'
            attribute_value_node = attribute.children.find { |child| child.name == 'value' }
            user_data['email'] = attribute_value_node.text
          end

          if attribute.attributes['name'].value == 'displayName'
            attribute_value_node = attribute.children.find { |child| child.name == 'value' }
            user_data['name'] = attribute_value_node.text
          end
        end

        if user_data['email'].present? == false || user_data['name'].present? == false
          sleep 0.1
        else
          break
        end
      end

      raise("Email or name missing for #{cas_data_file}") if user_data['email'].present? == false || user_data['name'].present? == false

      user = User.where(email: user_data['email']).first
      unless user
        user = User.new(
          username: user_data['email'].sub('@', '.'),
          email: user_data['email']
        )
        user.save!
      end
    rescue => e
      logger.error(e)

      render 'users/no_auth', layout: 'login'
    end

    @session_user = user
  end

  def is_admin
    redirect_to root_url unless @session_user.superadmin
  end

  def use_fake_auth
    fake_user = User.where(email: 'timetracker_fake_user@example.com').first

    if fake_user.nil?
      fake_user = User.create!(
        username: 'timetracker_fake_user',
        email: 'timetracker_fake_user@example.com',
        superadmin: true
      )
    end

    @session_user = fake_user
  end
end
