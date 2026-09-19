class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch('MAIL_FROM', 'noreply@qoodish.com') }
  layout 'mailer'
end
