namespace :deploy do
  task :ensure_clean_repo do
    Dir.chdir Rails.root
    if ! system("git diff-index --quiet HEAD")
      raise "Please commit or stash your changes first"
    end

    branchname = `git describe --contains --all HEAD`.strip
    if ! system("git diff-tree --quiet origin/#{branchname} #{branchname}")
      raise "Please push your changes first"
    end
  end

  desc 'Create tag for deployment from what is committed and pushed on the current branch'
  task :tag => [:ensure_clean_repo] do
    Dir.chdir Rails.root
    tag = "v#{Time.now.strftime('%Y%m%d%H%M%S')}"
    system("git tag -a #{tag} -m '' && git push origin #{tag}") or raise "Failed to tag"
    puts "URL: #{tag}"
  end
end
