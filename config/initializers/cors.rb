Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins (ENV['CORS_ALLOWED_ORIGINS'] || []).split(',')
    resource '*', headers: :any, methods: :any, credentials: true
  end
end
