class ApplicationMailer < ActionMailer::Base
  default from: Timetracker::Application.config.default_sender,
          return_path: Timetracker::Application.config.return_path,
          template_path: 'mailers'

  layout 'mailer'
end
