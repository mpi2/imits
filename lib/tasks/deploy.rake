namespace :deploy2 do
  def git_modifications?
    # Doing a git status first seems to be the only way to make git diff
    # reliably return a status code reflecting whether or not changes have been
    # made!
    return ! system('git status &> /dev/null ; git diff --quiet')
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

  task :generate_assets => [:ensure_clean_repo] do
    Dir.chdir Rails.root
    FileUtils.rm_rf 'public/assets'
    system('bundle exec jammit') or raise 'Jammit failed'
    if git_modifications?
      puts 'Re-generating assets'
      system('git commit -m "Re-generate assets" public/assets; git push')
    end
  end

  desc "Create tag for deployment from what is committed and pushed on the current branch\n" +
     "exception: will generate, commit and push compressed assets if not already done"
  task :tag => [:ensure_clean_repo, :generate_assets] do
    Dir.chdir Rails.root
    tag = "v#{Time.now.strftime('%Y%m%d%H%M%S')}"
    system("git tag -a #{tag} -m '' && git push origin #{tag}") or raise 'Failed to tag'
    puts "URL: https://github.com/mpi2/imits/tarball/#{tag}"
  end
end
