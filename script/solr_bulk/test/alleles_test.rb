#!/usr/bin/env ruby

require 'pp'
require 'color'

STDOUT.sync = true

class AllelesTest
  def initialize
    @count = 0
    @failures = []
    # 26749 is duplicated because of unique_public_info in app/models/targ_rep/allele.rb ?
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
    end

    failed
  end

  def dump_hash hash
    puts "{"
    hash.keys.sort.each do |key|
      if hash[key].to_s.empty?    #|| hash[key].to_a.empty?
        hash.delete(key)
        next
      end

      puts "\t#{key}: #{hash[key]}"
    end
    puts "}"
  end

  def test_solr_alleles
    @count = 0
    @failed_count = 0
    count = 0
    @ids = []

    hash = {}

    log 'start building hash...'

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
    end

    pp @failures

    if ! @failures.empty?
      id = 0
      docs = nil
      count = 0

      TargRep::TargetedAllele.where(:id => @failures).each do |allele|
        #puts "#### start 1:"
        #pp allele.attributes
        #puts "#### end 1:"

        docs = SolrUpdate::DocFactory.create_for_allele(allele)

        next if ! docs || docs.empty?

        count += 1

        #puts "#### stuff start:"
        #pp docs
        #puts "#### stuff end"

        id = docs.first['id'].to_i
        #dump_hash docs.first
        # break

        #doc.each do |doc|
        #  dump_hash hash[id].first
        #  dump_hash hash[id].first
        #end
      end

      puts "#### count: #{count}"

      pp docs
      pp hash[id]

      # pp hash[id]
      #   dump_hash hash[id].first

      #  puts "#### sizes: #{docs.size}/#{hash[id].size}"

      return
    end

    # exit

    log "end loop (#{count})..."

    log 'start main loop...'

    batch_counter = 0
    TargRep::TargetedAllele.find_in_batches(:batch_size => @batch_size) do |group|
      batch_counter += @batch_size
      log "batch: #{batch_counter}"

      group.each do |allele|

        docs = SolrUpdate::DocFactory.create_for_allele(allele)

        if ! docs || docs.empty?
          next
        end

        docs.each do |doc|
          old = doc

          @count += 1

          ok = false

          hash[old['id']].each do |new|
            ok = ! compare(old, new)
            break if ok
          end

          if ! ok
            @failed_count += 1
            puts "#### #{old['id']}: failed!".red
            @failures.push old['id']
          end
        end
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

    log 'starting old loop...'

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
      if @hash_old[key].to_i != @hash_new[key].to_i
        allele = TargRep::TargetedAllele.find key
        docs = SolrUpdate::DocFactory.create_for_allele(allele)

        if docs.first == docs.last
          puts "#### #{key} is duplicated!"
          @count_old -= 1
          next
        else
          puts "#### #{key} is error!"
        end

        puts "#### #{key}: #{@hash_old[key].to_i}/#{@hash_new[key].to_i}"
      end
    end

    puts "#### done test_solr_alleles_counts: (#{@count_old}/#{@count_new})".red if @count_old != @count_new
    puts "#### done test_solr_alleles_counts: (#{@count_new})".green if @count_old == @count_new
  end

  def run
    puts "#### starting alleles...".blue

    if @enabler['test_solr_alleles_counts']
      test_solr_alleles_counts
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
