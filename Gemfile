ruby '2.3.0'
source 'https://rubygems.org'

source 'https://rails-assets.org' do
  gem 'rails-assets-momentjs'
end

gem 'rails', '4.2.5'
gem 'api-pagination'
gem 'autoprefixer-rails'
gem 'carrierwave'
gem 'chroma'
gem 'cloudinary'
gem 'coffee-rails'
gem 'connection_pool'
gem 'dalli'
gem 'doorkeeper'
gem 'faker'
gem 'freemail'
gem 'haml'
gem 'httparty'
gem 'intercom-rails'
gem 'intercom', "~> 3.5.9"
gem 'jbuilder'
gem 'jquery-rails'
gem 'kaminari'
gem 'mail', '2.6.5'
gem 'mailgunner', '~> 2.6.0'
gem 'namae'
gem 'octokit'
gem 'omniauth'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'omniauth-slack'
gem 'paranoia', '~> 2.0'
gem 'pg'
gem 'premailer-rails'
gem 'puma'
gem 'pundit'
gem 'rack-cors'
gem 'rack-rewrite'
gem 'rails-api' # This is included in Rails 5, so look at again when upgrade time comes
gem 'rails_12factor'
gem 'redcarpet'
gem 'redis-rails'
gem 'restforce'
gem 'ruby-saml'
gem 'sass-rails'
gem 'scout_apm'
gem 'sentry-raven'
gem 'sequel' # This is just used for migration purposes, once we stop migrating, remove this
gem 'sidekiq'
gem 'sinatra', require: false
gem 'skylight'
gem 'slack-ruby-client'
gem 'sorcery'
gem 'stripe'
gem 'stripe-ruby-mock', '~> 2.3.1', require: 'stripe_mock', git: 'https://github.com/smingins/stripe-ruby-mock.git', ref: '1503f590'
gem 'textacular', '~> 4.0'
gem 'twitter-text'
gem 'uglifier'
gem 'mechanize', '~> 2.7', '>= 2.7.4'
gem 'htmlentities', '~> 4.3', '>= 4.3.4'
gem 'bitmask_attributes'
gem 'intl-tel-input' # cute phone inputs
gem 'phony_rails'    # and backend validations for them
gem 'dotenv'
gem 'rack-tracker'
gem 'whenever', :require => false
# For basic admin graphs
gem 'chartkick'
gem 'rails_emoji_picker'

gem "recaptcha", require: "recaptcha/rails"

# For better email signature parsing
gem 'email_reply_parser'
gem 'jquery-ui-rails'
gem 'rails_sortable'

group :development, :test do
  gem 'spring'
  gem "factory_girl_rails", "~> 4.0"
  gem 'foreman'
  gem 'guard', '>= 2.2.2', require: false
  gem 'guard-livereload'
  gem 'guard-minitest', require: false
  gem 'terminal-notifier-guard', require: false
  gem 'dotenv-rails'
  gem 'rubocop'
  gem 'letter_opener'
  gem 'rack-mini-profiler'
  gem 'pry-rails', '~> 0.3.4'
  gem 'bullet' # https://github.com/flyerhzm/bullet query analyzer
  gem 'mysql'
end

group :test do
  gem 'capybara'
  gem 'capybara-email'
  gem 'minitest-rails-capybara'
  gem 'launchy'
  gem 'minitest-reporters'
  gem 'mocha'
  gem 'poltergeist'
  gem 'shoulda'
  gem 'test_after_commit'
  gem 'codeclimate-test-reporter', require: nil
  gem 'fakeweb'
  gem 'simplecov', require: nil
  gem 'timecop'
end

group :doc do
  gem 'sdoc', '~> 0.4.0', group: :doc
end
