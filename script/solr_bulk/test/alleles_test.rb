#!/usr/bin/env ruby

require 'pp'
require 'color'

STDOUT.sync = true

class AllelesTest
  def initialize
    @count = 0
    @failed_count = 0
    @batch_size = 1000

    @enabler = {
      'test_solr_alleles' => true
    }
  end

  #{"type"=>"allele",
  #   "id"=>162,
  #   "product_type"=>"ES Cell",
  #   "allele_id"=>162,
  #   "order_from_names"=>"EUMMCR;",
  #   "order_from_urls"=>"http://www.eummcr.org/order.php;",
  #   "mgi_accession_id"=>"MGI:101802",
  #   "simple_allele_image_url"=>
  #    "http://localhost:3000/targ_rep/alleles/162/allele-image?simple=true",
  #   "marker_symbol"=>"F2r",
  #   "allele_image_url"=>
  #    "http://localhost:3000/targ_rep/alleles/162/allele-image",
  #   "genbank_file_url"=>
  #    "http://localhost:3000/targ_rep/alleles/162/escell-clone-genbank-file",
  #   "allele_type"=>"Conditional Ready",
  #   "strain"=>"C57BL/6N-A<tm1Brd>/a",
  #   "allele_name"=>"F2r<sup>tm1a(EUCOMM)Hmgu</sup>",
  #   "project_ids"=>["125824"],
  #   "project_statuses"=>[],
  #   "project_pipelines"=>[],
  #   "vector_project_ids"=>[],
  #   "vector_project_statuses"=>[]}

  def log message
    puts "#### #{message}"
  end

  def compare old, new, silent = true
    # log "compare..."

    #pp old
    #pp news

    splits = %W{order_from_names order_from_urls project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    failed = false

    # news.each do |new|
    #splits.each do |split|
    #  old.delete(split) if ! old[split] || old[split].empty?
    #  new.delete(split) if ! new[split] || new[split].empty?
    #end

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

    #  @failed_count += 1 if failed
    #   end

    #difference = (old.size > new.size) ? old.to_a - new.to_a : new.to_a - old.to_a

    #failed || (difference && ! difference.empty?)

    failed
  end

  def test_solr_alleles
    @count = 0
    @failed_count = 0
    count = 0
    @ids = []

    hash = {}

    log 'start building hash...'

    #alleles = ActiveRecord::Base.connection.execute("select * from solr_alleles limit 1")
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

      hash[allele['id'].to_i] ||= []
      hash[allele['id'].to_i].push allele.clone
      count += 1
      @ids.push allele['id'].to_i
      #break if count > 10
    end

    log "end loop (#{count})..."

    log 'start main loop...'

    #TargRep::TargetedAllele.all.each do |allele|
    TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
      #TargRep::TargetedAllele.find(:id => @ids) do |allele|
      # log 'start create_for_allele...'
      docs = SolrUpdate::DocFactory.create_for_allele(allele)
      # log 'end create_for_allele...'

      # puts "#### ignoring...".red if ! docs || docs.empty?
      next if ! docs || docs.empty?

      @count += docs.size

      #next
      #pp docs
      #break

      # log "docs (#{docs.size})..."

      docs.each do |doc|
        old = doc

        #allele.es_cells.each do |es_cell|
        #  rows = ActiveRecord::Base.connection.execute("select * from solr_alleles(#{es_cell.id})")
        #
        #  count = 0
        #  new = ''
        #  rows.each do |row|
        #    new = row['solr_get_allele_order_from_urls']
        #    count += 1
        #  end
        #
        #  raise "#### invalid count detected!".red if count != 1
        #
        #  #pp new
        #  @count += 1
        # # break
        #end

        @count += 1
        #break
        #break if @count == 10

        if ! hash.has_key? old['id']
          puts "#### #{old['id']}: cannot find in hash!".red
          @failed_count += 1
          next
        end

        ok = false

        hash[old['id']].each do |new|
          ok = ! compare(old, new)
          break if ok
        end

        if ! ok
          @failed_count += 1
          puts "#### #{old['id']}: failed!".red
          if hash[old['id']].size == 1
           # pp old
          #  pp hash[old['id']]
            compare old, hash[old['id']].first, false
           # exit
          end
        end

        #compare old, hash[old['id']]

        #  break
      end

      break if @count >= 1000

      #  break if @count >= 10000
    end

    log 'end main loop...'

    #puts "#### count error: (#{count}/#{@count})".red if count != @count
    puts "#### count error: (#{@count}/#{count})".red if count != @count
  end

  def run
    puts "#### starting alleles...".blue

    if @enabler['test_solr_alleles']
      test_solr_alleles

      puts "#### done test_solr_alleles: (#{@failed_count}/#{@count})".red if @failed_count > 0
      puts "#### done test_solr_alleles: (#{@count})".green if @failed_count == 0
    end
  end
end

AllelesTest.new.run if File.basename($0) !~ /rake/
