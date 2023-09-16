Rails.application.routes.draw do
  # Admin routes
  namespace :admin do
    get '/' => 'dashboard#acquisition', as: :dashboard
    get '/dashboard/acquisition' => 'dashboard#acquisition', as: :acquisition_dashboard
    get '/dashboard/migration' => 'dashboard#migration', as: :migration_dashboard
    get '/dashboard/usage' => 'dashboard#usage', as: :usage_dashboard
    resources :organizations
    resources :users do
      member do
        post :log_in_as_user
        put :restore, as: :restore
        post :send_reset
        post :verify_email
        post :reset_api_token
        delete :hard_delete
      end
    end
    resources :teams
    resource :app_settings, path: 'settings'
    resource :session, only: [:new, :create]
    resources :intercom_queues, only: [:index]

    # mount sidekiq web and protect behind admin auth ... if first route fails due
    # to constraint it will route to the dashboard and prompt for admin login
    require 'sidekiq/web'
    require 'admin_constraint'
    mount Sidekiq::Web => '/sidekiq', :constraints => AdminConstraint.new
    get '/sidekiq', to: 'dashboard#acquisition'
  end
  # This route is exposed by omniauth so needs to live outside the admin namespace
  get '/auth/admin/callback' => 'admin/sessions#create'

  # migration routes
  get '/migrate' => 'migration#connect'
  get '/migrate/confirm' => 'migration#confirm'
  post '/migrate' => 'migration#execute_migration'
  get '/auth/idonethis/callback' => 'migration#oauth_callback'

  # Onboarding
  get 'migrate/one' => 'onboard#migrate_one'
  patch 'migrate/one' => 'onboard#migrate_one_save'
  get 'migrate/two' => 'onboard#migrate_two'
  patch 'migrate/two' => 'onboard#migrate_two_save'

  get 'onboard/one' => 'onboard#onboard_one'
  patch 'onboard/one' => 'onboard#onboard_one_save'
  get 'onboard/two' => 'onboard#onboard_two'
  patch 'onboard/two' => 'onboard#onboard_two_save'
  patch 'onboard/exit' => 'onboard#onboard_exit'
  get 'onboard/notice' => 'onboard#onboard_notice'

  # standard user dashboard

  resources :organizations, only: [:new, :create, :show, :update], path: 'o' do
    member do
      get :overdue
      get :stats
      get :export
      get :settings
      get :billing # partial
      get :billing_form # partial
      patch :billing_save # partial
      patch :saml_save # partial
      patch :customize
      get :invoices # partial
    end

    resources :teams, path: 't', only: [:new, :create]
    resources :users, path: 'u'
    resources :organization_memberships, path: 'memberships', only: [:index, :update, :destroy]
    resources :tags, only: [:show]
    resources :invitations, only: [:new, :create]
  end

  resources :teams, path: 't', only: [:show, :update, :destroy] do
    member do
      get :search
      get :stats
      get :calendar
      get :export
      get :settings
      post :join
      patch :customize # partial
      get :calendar_month # partial
      get :brief # partial
    end

    resources :tags, only: [:show]
    resources :entries, only: [:create, :update]
    resources :team_memberships, path: 'memberships', only: [:new, :create, :update, :destroy, :index] do
      member do
        get :notifications # partial
        patch :notifications_save # partial
        get :unsubscribe_comments_notification
        get :unsubscribe_mentions_notification
        get :unsubscribe_digests
        get :unsubscribe_reminders
        patch :unthrottle_emails
        get :unsubscribe_assign_task_reminders
      end
    end
    resources :invitations, only: [:create]
  end

  resources :entries, path: 'e', only: [:show, :edit, :destroy] do
    member do
      get :brief # partial
      get :assign # partial
      post :toggle_like # partial
      post :mark_done # partial
      post :archive # partial
    end
    resources :reactions, only: [:create, :update, :destroy] # partial
  end

  resources :reactions, only: [:show, :edit], path: 'r'

  resource :user, only: [:update], path: 'u' do
    member do
      post :go_by_for_full_name

      get :settings
      patch :personalize
      patch :change_password
    end
  end

  resources :integrations, only: [:index]
  resources :invitations, only: [:destroy], path: 'i' do
    member do
      post :resend
      patch :accept
      patch :decline
    end
  end

  resources :alternate_emails, only: [:create, :destroy]
  get 'alternate_emails/:verification_code/verify', to: 'alternate_emails#verify', as: :verify_alternate_email
  
  resources :notifications, only: [:index, :destroy]

  post 'notifications' => 'notifications#clear'
  get 'notifications/reload_archived' => 'notifications#reload_archived'
  patch 'entry_listing' => 'teams#user_entry_listing'
  root 'organizations#default'

  # User & Auth

  ## Use doorkeeper for OAuth provider functionality
  use_doorkeeper

  ## SAML SSO routes
  resources :saml, only: [] do
    collection do
      get  'sso/:id' => 'saml#sso'
      post 'consume/:id' => 'saml#consume'
      get  'metadata/:id' => 'saml#metadata'
    end
  end

  ## Upgrade to $$ plan

  get 'o/:organization_id/upgrade/subcription_failes' => 'upgrade#subcription_failes', as: :subcription_failes
  get 'o/:organization_id/upgrade' => 'upgrade#show', as: :organization_upgrade
  get 'o/:organization_id/upgrade/billing' => 'upgrade#billing', as: :organization_upgrade_billing
  patch 'o/:organization_id/upgrade/complete' => 'upgrade#complete', as: :organization_upgrade_complete
  ## Normal user+session management routes
  resources :users, only: [:create] do
    collection do
      get 'reset_password' => 'users#request_reset'
      post 'reset_password' => 'users#request_reset'
      patch 'reset_api_token' => 'users#reset_api_token'
      get 'reset_password/:password_reset_token' => 'users#reset_password', as: :reset
      post 'reset_password/:password_reset_token' => 'users#reset_password'
      get 'verify/:verification_token' => 'users#verify', as: :verify
    end
  end

  get 'register(/:invitation_code)' => 'users#new', as: :register
  resources :user_sessions, only: [:new, :create, :destroy]
  get 'login' => 'user_sessions#new', as: :login
  post 'login' => 'user_sessions#create'
  post 'logout' => 'user_sessions#destroy', as: :logout
  get  '/auth/:provider' => "user_sessions#oauth", as: :auth_at_provider
  get  '/auth/google/callback' => 'user_sessions#oauth_callback'

  # API Routes
  namespace :api do
    namespace :v2 do
      get 'noop' => 'noop#index'
      post 'login' => 'sessions#create'
      post 'logout' => 'sessions#destroy', as: :logout
      post 'gmail_login' => 'sessions#gmail_login'
      resources :entries, only: [:index, :create, :show, :update, :destroy] do
        member do
          get :assign
          post :toggle_like
          post :mark_done
        end
        collection do
          get 'date_wise_entry_list' => 'entries#date_wise_entry_list'
        end
      end
      resources :hooks, only: [:index, :create, :show, :update, :destroy]
      resources :team_memberships, only: [:create,:update,:destroy] do 
        member do
          patch :notifications_save
        end
        collection do
          get 'fetch_team_membership' => 'team_memberships#fetch_team_membership'
        end
      end
      resources :teams, only: [:create, :index, :show, :update] do
        member do
          get :members
          get :entries
        end
      end
      resources :users do
        collection do
          get :request_reset
        end
        member do
          post :personalize
        end
      end
      resources :reactions
      resources :organizations, only: [:show] do
        collection do
          get :user_org
        end
      end

    end
  end

  ## Slack
  get    '/auth/slack/callback'     => 'integrations/slack#oauth_callback'
  get    '/integrations/slack/link' => 'integrations/slack#new_link'
  post   '/integrations/slack/link' => 'integrations/slack#create_link'
  delete '/integrations/slack/link' => 'integrations/slack#destroy_link'
  post   '/integrations/slack/hook' => 'integrations/slack#hook'
  ## Github
  get    '/auth/github/callback'     => 'integrations/github#oauth_callback'
  get    '/integrations/github/link' => 'integrations/github#new_link'
  post   '/integrations/github/link' => 'integrations/github#create_link'
  delete '/integrations/github/link' => 'integrations/github#destroy_link'
  post   '/integrations/github/hook/:token' => 'integrations/github#hook'
  ## Inbound Email
  post '/integrations/inbound_emails' => 'integrations/inbound_emails#create'
  ## Stripe Webhooks
  post '/stripe/hook' => 'stripe#hook'

  # Error routes
  get "/todo" => "errors#todo"
  get "/incorrect_organization" => "errors#incorrect_organization"
  get "/404" => "errors#not_found"
  get "/500" => "errors#internal_server_error"

  # Static pages
  get '/about' => 'pages#about'
end
