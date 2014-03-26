#!/usr/bin/env ruby

require 'pp'
require 'color'

STDOUT.sync = true

class AllelesTest
  def initialize
    @count = 0
    @failures = []
    @failed_count = 0
    @batch_size = 500

    @enabler = {
      'test_solr_alleles' => false,
      'test_solr_alleles_counts' => true
    }
  end

  def log message
    puts "#### #{message}"
  end

  def compare old, new, silent = true
    splits = %W{order_from_names order_from_urls project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    failed = false

    splits.each do |split|
      old.delete(split) if ! old[split] || old[split].empty?
      new.delete(split) if ! new[split] || new[split].empty?
    end

    if old.keys.size != new.keys.size
      puts "#### #{old['id']}: key count error (#{old.keys.size}/#{new.keys.size})".red
      diff = old.keys - new.keys
      diff = new.keys - old.keys if ! diff || diff.empty?
      pp diff if ! silent
      failed = true
    end

    splits.each do |split|
      old[split] = old[split].to_a.sort.uniq
      new[split] = new[split].to_a.sort.uniq

      next if old[split].empty? && new[split].empty?

      if old[split].size != new[split].size
        puts "#### #{old['id']}: split key count error (#{old[split].size}/#{new[split].size})".red if ! silent
        failed = true
        next
      end

      for i in 0..old[split].size
        if old[split][i].to_s != new[split][i].to_s
          puts "#### #{old['id']}: '#{split}': compare error (#{old[split][i]}/#{new[split][i]})".red if ! silent
          failed = true
        end
      end
    end

    old.keys.each do |key|
      next if splits.include? key
      if old[key].to_s != new[key].to_s
        puts "#### #{old['id']}: '#{key}': compare error 2 (#{old[key].to_s}/#{new[key].to_s})".red if ! silent
        failed = true
      end
    end

    difference = (old.size > new.size) ? old.to_a - new.to_a : new.to_a - old.to_a

    if ! silent && difference && ! difference.empty?
      puts "#### difference:"
      pp difference
      #pp old
      #pp new
      #  exit
    end

    failed
  end

  def test_solr_alleles
    @count = 0
    @failed_count = 0
    count = 0
    @ids = []

    hash = {}

    log 'start building hash...'

    #alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles where id = 235")
    alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles")

    splits = %W{order_from_names order_from_urls project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    ints = %W{id allele_id}

    log 'start loop...'

    alleles.each do |allele|
      splits.each do |split|
        allele[split] = allele[split].to_s.split(';')
      end

      ints.each do |i|
        allele[i] = allele[i].to_i
      end

      hash[allele['id']] ||= []
      hash[allele['id']].push allele.clone
      count += 1
      @ids.push allele['id']

      #if allele['id'] == 235
      #  puts "#### found!".green
      #end
    end

    log "end loop (#{count})..."

    log 'start main loop...'

    #TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
    #TargRep::TargetedAllele.find(:id => @ids) do |allele|
    # alleles.each do |allele|

    #  allele_old = TargRep::TargetedAllele.find_by_id allele['id']

    #pp @failures
    #exit

    batch_counter = 0
    TargRep::TargetedAllele.find_in_batches(:batch_size => @batch_size) do |group|
      batch_counter += @batch_size
      log "batch: #{batch_counter}"

      group.each do |allele|

        #    TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
        #TargRep::TargetedAllele.where(:id => @failures).each do |allele|
        #log 'start create_for_allele...'
        docs = SolrUpdate::DocFactory.create_for_allele(allele)

        #if ! allele_old
        #  puts "#### #{allele['id']}: cannot find in db!".red
        #  @failed_count += 1
        #  next
        #end

        #docs = SolrUpdate::DocFactory.create_for_allele(allele_old)

        if ! docs || docs.empty?
          #log 'no doc!'
          #puts "#### #{allele['id']}: cannot find in docs!".red
          #@failed_count += 1
          next
        end

        #@count += docs.size

        docs.each do |doc|
          old = doc

          @count += 1

          #if ! hash.has_key? old['id'].to_i
          #  puts "#### #{old['id']}: cannot find in hash!".red
          #  @failed_count += 1
          #  next
          #end

          ok = false

          hash[old['id']].each do |new|
            ok = ! compare(old, new)
            break if ok
          end

          if ! ok
            @failed_count += 1
            puts "#### #{old['id']}: failed!".red
            #if hash[old['id']].size == 1
            #  compare old, hash[old['id']].first, false
            #  pp old
            #  pp hash[old['id']].first
            # # exit
            #end
            @failures.push old['id']
          end
        end

        #break if @count >= 10000
      end
    end

    log 'end main loop...'

    puts "#### count error: (#{@count}/#{count})".red if count != @count
  end

  def test_solr_alleles_counts
    @count_new = 0
    @count_old = 0
    @hash_new = {}
    @hash_old = {}

    log 'starting new loop...'

    alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles")
    alleles.each do |allele|
      @hash_new[allele['id'].to_i] ||= 0
      @hash_new[allele['id'].to_i] += 1
      @count_new += 1
    end

    #log 'starting new count...'
    #@count_new = ActiveRecord::Base.connection.execute("SELECT COUNT(*) as count FROM solr_alleles").fetch_hash['count']

    log 'starting old loop...'

    #TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
    batch_counter = 0
    TargRep::TargetedAllele.find_in_batches(:batch_size => @batch_size) do |group|
      batch_counter += @batch_size
      log "batch: #{batch_counter}"
      group.each do |allele|
        docs = SolrUpdate::DocFactory.create_for_allele(allele)
        next if ! docs || docs.empty?
        @count_old += docs.size
        @hash_old[allele.id] ||= 0
        @hash_old[allele.id] += docs.size
      end
    end

    log 'done old loop...'

    if @count_old != @count_new
      old_keys = @hash_old.keys.sort
      new_keys = @hash_new.keys.sort

      diff = old_keys.size > new_keys.size ? old_keys - new_keys : new_keys - old_keys

      puts "#### diff:"
      pp diff
      puts "#### diff.size: #{diff.size}"
    end

    @hash_old.keys.each do |key|
      puts "#### #{key}: #{@hash_old[key].to_i}/#{@hash_new[key].to_i}" if @hash_old[key].to_i != @hash_new[key].to_i
    end

    puts "#### done test_solr_alleles_counts: (#{@count_old}/#{@count_new})".red if @count_old != @count_new
    puts "#### done test_solr_alleles_counts: (#{@count_new})".green if @count_old == @count_new
  end

  def run
    puts "#### starting alleles...".blue

    if @enabler['test_solr_alleles_counts']
      test_solr_alleles_counts

      #puts "#### done test_solr_alleles_counts: (#{@failed_count}/#{@count})".red if @failed_count > 0
      #puts "#### done test_solr_alleles_counts: (#{@count})".green if @failed_count == 0
      #pp @failures if ! @failures.empty?
    end

    if @enabler['test_solr_alleles']
      test_solr_alleles

      puts "#### done test_solr_alleles: (#{@failed_count}/#{@count})".red if @failed_count > 0
      puts "#### done test_solr_alleles: (#{@count})".green if @failed_count == 0

      pp @failures if ! @failures.empty?
    end
  end
end

AllelesTest.new.run if File.basename($0) !~ /rake/
