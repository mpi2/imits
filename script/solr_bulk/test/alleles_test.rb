#!/usr/bin/env ruby

require 'pp'
require 'color'

STDOUT.sync = true

class AllelesTest
  def initialize
    @count = 0
    @failures = []
    @failed_count = 0
    @batch_size = 1000

    @enabler = {
      'test_solr_alleles' => true
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

    TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
      #TargRep::TargetedAllele.find(:id => @ids) do |allele|
      # log 'start create_for_allele...'
      docs = SolrUpdate::DocFactory.create_for_allele(allele)

      #if ! allele_old
      #  puts "#### #{allele['id']}: cannot find in db!".red
      #  @failed_count += 1
      #  next
      #end

      #docs = SolrUpdate::DocFactory.create_for_allele(allele_old)

      if ! docs || docs.empty?
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
          #end
          @failures.push old['id']
        end
      end

      #break if @count >= 10000
    end

    log 'end main loop...'

    puts "#### count error: (#{@count}/#{count})".red if count != @count
  end

  def test_solr_alleles_counts
    @count_new = 0
    @count_old = 0

    alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles")

    alleles.each do |allele|
      @count_new += 1
    end

    TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
      docs = SolrUpdate::DocFactory.create_for_allele(allele)
      next if ! docs
      @count_old += docs.size
    end

    puts "#### count error: (#{@count_old}/#{@count_new})".red if @count_old != @count_new
  end

  def run
    puts "#### starting alleles...".blue

    if @enabler['test_solr_alleles']
      test_solr_alleles

      puts "#### done test_solr_alleles: (#{@failed_count}/#{@count})".red if @failed_count > 0
      puts "#### done test_solr_alleles: (#{@count})".green if @failed_count == 0

      pp @failures if @failures && ! @failures.empty?
    end
  end
end

AllelesTest.new.run if File.basename($0) !~ /rake/
