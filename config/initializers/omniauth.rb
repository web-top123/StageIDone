module OmniAuth
  module Strategies
    autoload :Idonethis, Rails.root.join('lib','idt_oauth2')
  end
end

Rails.application.config.middleware.use OmniAuth::Builder do
  # OAauth for slack integration
  provider :slack, ENV['SLACK_API_KEY'], ENV['SLACK_API_SECRET'], scope: 'commands, channels:read, chat:write:bot'

  # OAauth for github integration
  provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'], scope: 'user:email,repo,write:repo_hook'

  # This is the google oauth provider for logging in to admin
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], { name: 'admin' }

  # This is just used by the migration script to identify a user in the old system
  # once migrations aren't happening anymore please remove this.
  provider :idonethis,
    ENV['IDT1_CLIENT_ID'],
    ENV['IDT1_CLIENT_SECRET'],
    scope: 'read write',
    callback_path: '/auth/idonethis/callback'
end
