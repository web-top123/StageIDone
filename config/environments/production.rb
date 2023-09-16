Rails.application.configure do
  # If we want to use route helpers with '_url' affix, we need to tell the
  # Rails about the hotsname/port
  routes.default_url_options = {
    host: ENV['DOMAIN_NAME'],
  }

  config.cache_classes = false
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  # config.cache_store = :dalli_store,
  #                     (ENV["MEMCACHIER_SERVERS"] || "").split(","),
  #                     {:username => ENV["MEMCACHIER_USERNAME"],
  #                      :password => ENV["MEMCACHIER_PASSWORD"],
  #                      :failover => true,
  #                      :socket_timeout => 1.5,
  #                      :socket_failure_delay => 0.2,
  #                      :pool_size => 5
  #                     }
  config.cache_store = :null_store
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.js_compressor = :uglifier
  config.assets.compile = false
  config.assets.digest = true
  config.force_ssl = true
  config.log_level = :debug
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
  config.active_job.queue_adapter = :sidekiq


  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  # NOTE: ENV['MAILGUN_INBOUND_EMAIL_API_KEY'] is actually the same
  #       as ENV['MAILGUN_API_KEY']. However, since we use the latter
  #       as a indicator (in this file) to determine if we should set our
  #       mailer as mailgun (in production), but we require the same key
  #       to verify Mailgun emails forwarded to the inbound_controller,
  #       we use a different key name for use by the inbound_controller
  config.mailgun = {
    inbound_email_api_key: ENV['MAILGUN_INBOUND_EMAIL_API_KEY']
  }
  if ENV['MAILGUN_API_KEY']
    # config.action_mailer.delivery_method     = :mailgun
    # config.action_mailer.mailgun_settings    = {domain: ENV['MAILGUN_DOMAIN'], api_key: ENV['MAILGUN_API_KEY']}
    config.action_mailer.raise_delivery_errors = true #useful to have to debug
    config.action_mailer.perform_deliveries = true #default value
    config.action_mailer.delivery_method = :mailgun
    config.action_mailer.mailgun_settings = {
      api_key: '8a0525bfd881dee81ad3c8ea0bb099d7-413e373c-29a20f65',
      domain: 'entry.idonethis.com',
      user_name: 'postmaster@your_verified_domain.com',
      address: 'smtp.mailgun.org',
      port: 587,
      authentication: :plain,
      enable_starttls_auto: true    # Enable TLS encryption
    }
  else
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: ENV['SMTP_PORT'],
      domain: ENV['DOMAIN_NAME'],
      authentication: "plain",
      enable_starttls_auto: true,
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD']
    }
  end

  config.action_mailer.asset_host = "https://#{ENV['DOMAIN_NAME']}"
  config.action_mailer.default_url_options = { host: ENV['DOMAIN_NAME'] }
end
