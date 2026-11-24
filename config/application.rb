require_relative 'boot'

require 'ipaddr'
require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Timetracker
  class Application < Rails::Application
    config.load_defaults 8.1

    config.active_record.default_timezone = :utc
    I18n.config.enforce_available_locales = true

    config.generators do |generate|
      generate.test_framework :rspec
      generate.helper false
      generate.stylesheets false
      generate.javascript_engine false
      generate.view_specs false
    end

    # Autoload and eager load lib/, ignoring non-Ruby subdirectories.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configure the default encoding used in templates.
    config.encoding = 'utf-8'

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.log_formatter = proc do |severity, datetime, progname, msg|
      timestamp = datetime.strftime '%Y-%m-%d %H:%M:%S (%Z)'
      "#{timestamp} #{severity}: #{progname} #{msg}\n"
    end

    # Set host allowed by the application
    config.hosts << ENV['ALLOWED_HOST'] if ENV['ALLOWED_HOST'].present?

    # Mailer settings
    config.default_sender = ENV['DEFAULT_SENDER'] || 'no-reply@example.com'
    config.return_path = ENV['RETURN_PATH'] || 'user@example.com'
    config.front_url = ENV['FRONT_URL'] || 'https://example.com'

    # Devise authentication type (db, cas, saml, or headers)
    config.devise_auth_type = ENV['DEVISE_AUTH_TYPE'] || 'db'

    # Header authentication: addresses allowed to send the X-Auth-* headers,
    # comma separated IPs or CIDR ranges (the auth proxy). Loopback only by default.
    config.auth_headers_trusted_proxies =
      (ENV['AUTH_HEADERS_TRUSTED_PROXIES'].presence || '127.0.0.1,::1')
        .split(',')
        .map(&:strip)
        .compact_blank
        .map { |proxy| IPAddr.new(proxy) }

    # External Devise authentication configuration
    if config.devise_auth_type == 'cas'
      require 'devise_cas_authenticatable'
      config.rack_cas.server_url = ENV['DEVISE_CAS_AUTH_URL'] || 'https://cas.example.com'
      config.rack_cas.service = ENV['DEVISE_CAS_AUTH_SERVICE_PATH'] || '/users/service'
    elsif config.devise_auth_type == 'saml'
      require 'devise_saml_authenticatable'
    end
  end
end
