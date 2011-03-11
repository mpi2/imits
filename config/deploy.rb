require File.dirname(__FILE__) + '/extjs.rb'

set :application, 'kermits-2'
set :repository,  'http://github.com/i-dcc/kermits-2.git'
set :branch, 'master'
set :user, `whoami`.chomp

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, 'etch-dev64.internal.sanger.ac.uk'
role :app, 'etch-dev64.internal.sanger.ac.uk'

set :default_environment, {
  'PATH'      => '/software/team87/brave_new_world/bin:/software/perl-5.8.8/bin:/usr/bin:/bin',
  'PERL5LIB'  => '/software/team87/brave_new_world/lib/perl5:/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi'
}

set :bundle_cmd, '/software/team87/brave_new_world/bin/htgt-env.pl --environment Ruby19 /software/team87/brave_new_world/app/ruby-1.9.2-p0/lib/ruby/gems/1.9/bin/bundle'

namespace :deploy do
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
    sleep 10
    run "rm #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"

    # /tmp
    run "mkdir -m 777 -p #{var_run_path}/tmp"
    run "cd #{release_path} && rm -rf tmp && ln -nfs #{var_run_path}/tmp tmp"

    # /public/javascripts - the server needs write access...
    run "rm -rf #{var_run_path}/javascripts"
    run "cd #{release_path}/public && mv javascripts #{var_run_path}/javascripts && ln -nfs #{var_run_path}/javascripts javascripts"
    run "chgrp team87 #{var_run_path}/javascripts && chmod g+w #{var_run_path}/javascripts"
  end

  desc "Install extjs-#{EXTJS_VERSION} into shared and then symlink it to public/extjs"
  task :extjs do
    run "cd #{release_path}/tmp && wget -q --no-clobber #{EXTJS_DOWNLOAD_URL}"
    run "cd #{release_path}/public && unzip -qn #{release_path}/tmp/ext-#{EXTJS_VERSION}.zip && " +
            "ln -sfn ext-#{EXTJS_VERSION} extjs"
  end

  desc "Set the permissions of the filesystem so that others in the team can deploy, and the team87 user can do their stuff"
  task :fix_perms do
    run "chgrp -R team87 #{release_path}/tmp"
    run "chgrp -R team87 #{release_path}/public"
    run "chmod 02775 #{release_path}"
  end
end

after "deploy:symlink", "deploy:fix_perms"
after "deploy:update_code", "deploy:symlink_shared"
after "deploy:symlink_shared", "deploy:extjs"
