set :application, "postkart"
set :repository,  "git@github.com:arsduo/Postkart.git"
set :domain, "postkart.alexkoppel.com"
set :deploy_to, "$HOME/rails_apps/#{application}/"

set :scm, :git
ssh_options[:forward_agent] = true
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "postkart.alexkoppel.com"                          # Your HTTP server, Apache/etc
role :app, "postkart.alexkoppel.com"                          # This may be the same as your `Web` server

# authentication
set :user, "arsduo"
set :use_sudo, false

# bundler
require 'bundler/capistrano'
default_environment['PATH']='/usr/lib/ruby/gems/1.8/bin:/home/arsduo/.gems/bin:/usr/local/bin:/usr/bin:/bin'
default_environment['GEM_PATH']='/home/arsduo/.gems:/usr/lib/ruby/gems/1.8'

# passenger-specific deploy tasks
namespace :deploy do
  task :start do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  task :stop do
    # nothing
  end
  
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

# jammit
namespace :deploy do
  task :brew_coffee, :roles => :web do
    send(:run, "cd #{release_path} && bundle exec rake barista:brew")
  end
  
  task :generate_assets, :roles => :web do
    send(:run, "cd #{release_path} && bundle exec rake jammit:package_dreamhost_assets")
  end
end

# generate javascript from coffeescript, then compress it
after "deploy:restart", "deploy:brew_coffee"
after "deploy:brew_coffee", "deploy:generate_assets"

