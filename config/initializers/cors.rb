Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('CORS_ALLOWED_ORIGINS', '').split(',').map(&:strip).compact_blank
    resource '*', headers: :any, methods: :any, credentials: true
  end
end
