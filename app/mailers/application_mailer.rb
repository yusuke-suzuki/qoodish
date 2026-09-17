class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch('MAIL_FROM', 'noreply@qoodish.com') },
          reply_to: -> { ENV.fetch('MAIL_REPLY_TO', 'support@qoodish.com') }
  layout 'mailer'
end
