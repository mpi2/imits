namespace :deploy do
  def git_modifications?
    return ! system('git diff-index --quiet HEAD')
  end

  task :ensure_no_modifications do
    Dir.chdir Rails.root
    if git_modifications?
      raise 'Please commit or stash your modifications first'
    end
  end

  task :ensure_no_unpushed do
    Dir.chdir Rails.root
    branchname = `git describe --contains --all HEAD`.strip
    if ! system("git diff-tree --quiet origin/#{branchname} #{branchname}")
      raise 'Please push your changes first'
    end
  end

  task :ensure_clean_repo => [:ensure_no_modifications, :ensure_no_unpushed]

  task :assets => [:ensure_clean_repo] do
    Dir.chdir Rails.root
    FileUtils.rm_rf 'public/assets'
    system('bundle exec jammit') or raise 'Jammit failed'
    if git_modifications?
      puts 'Re-generating assets'
      system('git add public/assets; git commit -m "Re-generate assets"; git push')
    end
  end

  desc "Create tag for deployment from what is committed and pushed on the current branch\n" +
     "exception: will generate, commit and push compressed assets if not already done"
  task :tag => [:assets] do
    Dir.chdir Rails.root
    tag = "v#{Time.now.strftime('%Y%m%d%H%M%S')}"
    system("git tag -a #{tag} -m '' && git push origin #{tag}") or raise 'Failed to tag'
    puts "URL: https://github.com/mpi2/imits/tarball/#{tag}"
  end
end
