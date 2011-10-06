set :application, 'imits'
set :repository,  'git://github.com/i-dcc/imits.git'
set :branch, 'master'
set :user, `whoami`.chomp

set :scm, :git

set :keep_releases, 5
set :use_sudo, false

role :web, 'etch-dev64.internal.sanger.ac.uk'
role :app, 'etch-dev64.internal.sanger.ac.uk'

# role :web, 'localhost'
# role :app, 'localhost'
# set :ssh_options, { :port => 10027 }

set :default_environment, {
  'PATH'      => '/software/team87/brave_new_world/bin:/software/perl-5.8.8/bin:/usr/bin:/bin',
  'PERL5LIB'  => '/software/team87/brave_new_world/lib/perl5:/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi'
}

set :bundle_cmd, '/software/team87/brave_new_world/bin/htgt-env.pl --environment Live bundle'

namespace :deploy do
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')} && chmod ugo+w #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Symlink shared configs and directories on each release"
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

  desc "Install extjs into shared and then symlink it to public/extjs"
  task :extjs do
    run "cd #{release_path} && #{bundle_cmd} exec rake extjs:install"
  end

  desc "Generate CSS/JS assets with Jammit"
  task :generate_assets, :roles => :web do
    run "cd #{release_path} && #{bundle_cmd} exec jammit"
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
after "deploy:extjs", "deploy:generate_assets"

