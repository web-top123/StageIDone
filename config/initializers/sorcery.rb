Rails.application.config.sorcery.submodules = [:reset_password, :remember_me, :external]
Rails.application.config.sorcery.configure do |config|

  config.external_providers = [:google]
  config.google.key = ENV['GOOGLE_AUTH_CLIENT_ID']
  config.google.secret = ENV['GOOGLE_AUTH_CLIENT_SECRET']
  config.google.callback_url = ENV['GOOGLE_AUTH_CLIENT_CALLBACK_URL']
  config.google.user_info_mapping = {email_address: "email", full_name: "name", remote_portrait_url: "picture"}

  config.user_config do |user|
    user.username_attribute_names = [:email_address]
    user.downcase_username_before_authenticating = true
    user.reset_password_mailer = 'UsersMailer'
    user.reset_password_email_method_name = :reset_password
    user.reset_password_expiration_period = 3.days
    user.remember_me_for = 1.year
    # -- external --
    user.authentications_class = Authentication
  end

  config.user_class = 'User'
end
