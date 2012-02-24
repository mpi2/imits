Capistrano::Configuration.instance(true).load do
  before "deploy:update_code", "gitflow:calculate_tag"
  namespace :gitflow do
    desc "Calculate the tag to deploy"
    task :calculate_tag do
      # make sure we have any other deployment tags that have been pushed by others so our auto-increment code doesn't create conflicting tags
      `git fetch`

      tagMethod = "tag_#{stage}"
      send tagMethod

      # push tags and latest code
      system 'git push'
      if $? != 0
        raise "git push failed"
      end
      system 'git push --tags'
      if $? != 0
        raise "git push --tags failed"
      end
    end

    desc "Mark the current code as a staging/qa release"
    task :tag_staging do
      # find latest staging tag for today
      newTagDate = Date.today.to_s

      newTagSerial = 1

      todaysStagingTags = `git tag -l '#{application}-staging-#{newTagDate}.*'`
      todaysStagingTags = todaysStagingTags.split

      natcmpSrc = File.join(File.dirname(__FILE__), '/natcmp.rb')
      require natcmpSrc
      todaysStagingTags.sort! do |a,b|
        String.natcmp(b,a,true)
      end

      lastStagingTag = nil
      if todaysStagingTags.length > 0
        lastStagingTag = todaysStagingTags[0]

        # calculate largest serial and increment
        lastStagingTag =~ /#{application}-staging-[0-9]{4}-[0-9]{2}-[0-9]{2}\.([0-9]*)/
        newTagSerial = $1.to_i + 1
      end
      newStagingTag = "#{application}-staging-#{newTagDate}.#{newTagSerial}"

      shaOfCurrentCheckout = `git log --format=format:%H HEAD -1`
      shaOfLastStagingTag = nil
      if lastStagingTag
        shaOfLastStagingTag = `git log --format=format:%H #{lastStagingTag} -1`
      end

      if shaOfLastStagingTag == shaOfCurrentCheckout
        puts "Not re-tagging staging because the most recent tag (#{lastStagingTag}) already points to current head"
        newStagingTag = lastStagingTag
      else
        puts "Tagging current branch for deployment to staging as '#{newStagingTag}'"
        system "git tag -a -m 'tagging current code for deployment to staging' #{newStagingTag}"
      end

      set :branch, newStagingTag
    end

    desc "Mark the current code as a production release"
    task :tag_production do
      # find latest production tag for today
      newTagDate = Date.today.to_s

      newTagSerial = 1

      todaysProductionTags = `git tag -l '#{application}-production-#{newTagDate}.*'`
      todaysProductionTags = todaysProductionTags.split

      natcmpSrc = File.join(File.dirname(__FILE__), '/natcmp.rb')
      require natcmpSrc
      todaysProductionTags.sort! do |a,b|
        String.natcmp(b,a,true)
      end

      lastProductionTag = nil
      if todaysProductionTags.length > 0
        lastProductionTag = todaysProductionTags[0]

        # calculate largest serial and increment
        lastProductionTag =~ /#{application}-production-[0-9]{4}-[0-9]{2}-[0-9]{2}\.([0-9]*)/
        newTagSerial = $1.to_i + 1
      end
      newProductionTag = "#{application}-production-#{newTagDate}.#{newTagSerial}"

      shaOfCurrentCheckout = `git log --format=format:%H HEAD -1`
      shaOfLastProductionTag = nil
      if lastProductionTag
        shaOfLastProductionTag = `git log --format=format:%H #{lastProductionTag} -1`
      end

      if shaOfLastProductionTag == shaOfCurrentCheckout
        puts "Not re-tagging production because the most recent tag (#{lastProductionTag}) already points to current head"
        newProductionTag = lastProductionTag
      else
        puts "Tagging current branch for deployment to production as '#{newProductionTag}'"
        system "git tag -a -m 'tagging current code for deployment to production' #{newProductionTag}"
      end

      set :branch, newProductionTag
    end

  end
end