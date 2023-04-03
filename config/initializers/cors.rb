if Rails.env.development?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins 'http://127.0.0.1:6767'
      resource '*', headers: :any, methods: :any, credentials: true
    end
  end
end
