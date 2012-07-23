set :application, 'imits'
set :repository,  'git://github.com/mpi2/imits.git'
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
    restart_txt = File.join(current_path,'tmp','restart.txt')
    run "rm #{restart_txt} && touch #{restart_txt} && chmod ugo+w #{restart_txt}"
  end

  desc "Symlink shared configs and directories on each release"
  task :symlink_shared do
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"

    # /tmp
    run "mkdir -m 777 -p #{var_run_path}/tmp"
    run "cd #{release_path} && rm -rf tmp && ln -nfs #{var_run_path}/tmp tmp"
  end

  desc "Set the permissions of the filesystem so that others in the team can deploy, and the team87 user can do their stuff"
  task :fix_perms do
    run "find #{deploy_to}/ -user #{user}" + ' \! \( -perm -u+rw -a -perm -g+rw \) -exec chmod -v ug=rwX,o=rX {} \;'
  end
end

after "deploy:symlink", "deploy:fix_perms"
after "deploy:update_code", "deploy:symlink_shared"
