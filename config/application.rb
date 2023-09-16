require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IdtTwo
  class Application < Rails::Application
    config.time_zone = 'UTC'
    config.exceptions_app = self.routes
    config.generators do |g|
      g.assets false
    end

    config.active_record.raise_in_transactional_callbacks = true

    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '/api/*', :headers => :any, :methods => :any, credentials: false
      end
    end

    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 %r{^/(.*)/$}, '/$1'
    end

    # If we don't have this line, the `rails-api` gem will disable things like cookie_store and csrf
    config.api_only = false
    
    config.active_job.queue_adapter = :sidekiq

    # config.middleware.use(Rack::Tracker) do
    #   handler :facebook, { id: '887759594932189' }
    # end
  end
end
