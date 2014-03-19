#!/usr/bin/env ruby

require 'pp'
require 'color'

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

  def test_solr_alleles
    @count = 0
    @failed_count = 0
    count = 0

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

      hash[allele['id'].to_i] ||= []
      hash[allele['id'].to_i].push allele.clone
      count += 1
      #break if count > 10
    end

    log 'end loop...'

    log 'start main loop...'

    #TargRep::TargetedAllele.all.each do |allele|
    TargRep::TargetedAllele.find_each(:batch_size => @batch_size) do |allele|
      log 'start create_for_allele...'
      docs = SolrUpdate::DocFactory.create_for_allele(allele)
      log 'end create_for_allele...'

      next if ! docs || docs.empty?

      @count += docs.size
      next

      #pp docs
      #break

      docs.each do |doc|
        old = doc
        allele.es_cells.each do |es_cell|
          rows = ActiveRecord::Base.connection.execute("select * from solr_get_allele_order_from_urls(#{es_cell.id})")

          count = 0
          new = ''
          rows.each do |row|
            new = row['solr_get_allele_order_from_urls']
            count += 1
          end

          raise "#### invalid count detected!".red if count != 1

          #pp new
          @count += 1
         # break
        end

        #@count += 1
        #break
        #break if @count == 10
      end
    end

    log 'end main loop...'

    puts "#### count error: (#{count}/#{@count})".red if count != @count
  end

  def run
    if @enabler['test_solr_alleles']
      test_solr_alleles

      puts "#### done test_solr_alleles: (#{@failed_count}/#{@count})".red if @failed_count > 0
      puts "#### done test_solr_alleles: (#{@count})".green if @failed_count == 0
    end
  end
end

AllelesTest.new.run if File.basename($0) !~ /rake/
