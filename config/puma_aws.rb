require 'dotenv'
Dotenv.load("/home/ubuntu/idt-two/.env")

workers Integer(ENV['WEB_CONCURRENCY'] || 4)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"

rails_env= 'production'
environment 'production'
daemonize true
# Set master PID and state locations
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"

# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

activate_control_app

preload_app!

rackup      DefaultRackup
#port        ENV['PORT']     || 3000
#environment ENV['RACK_ENV'] || 'development'
#bind 'ssl://0.0.0.0:3000?key=/home/ubuntu/.ssh/server.key&cert=/home/ubuntu/.ssh/server.crt'
# Set up socket location
bind "unix://#{shared_dir}/sockets/puma.sock"

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
