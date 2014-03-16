#!/usr/bin/env ruby

require 'pp'
require 'color'

@count = 0
@failed_count = 0
@failed_mis = []

enabler = {
  'test_mi_attempt_allele_symbol' => false,
  'test_mi_attempt_order_from_names' => false,
  'test_mi_attempt_order_from_urls' => false,
  'test_get_best_status_pa' => false,
  'test_solr_mi_attempts' => true
}

def test_mi_attempt_allele_symbol
  @count = 0
  @failed_count = 0

  MiAttempt.all.each do |mi_attempt|
    #MiAttempt.where(:id => @failed_mis).each do |mi_attempt|
    next if mi_attempt.gene.mgi_accession_id.nil?

    if mi_attempt.has_status? :gtc and ! mi_attempt.has_status? :abt and mi_attempt.allele_id.to_i > 0 and mi_attempt.report_to_public
      old = mi_attempt.allele_symbol

      rows = ActiveRecord::Base.connection.execute("select * from solr_get_mi_allele_name(#{mi_attempt.id})")

      # pp rows.first

      count = 0
      new = ''
      rows.each do |row|
        new = row['solr_get_mi_allele_name']
        count += 1
      end

      raise "#### invalid count detected!".red if count != 1

      if old != new
        puts "#### error: #{mi_attempt.id}: (#{old}/#{new})".red
        @failed_count += 1
      end

      @count += 1
      #break if @count >= 1000
    end
  end
end

def test_mi_attempt_order_from_names
  @count = 0
  @failed_count = 0

  sql = 'CREATE temp table solr_get_mi_order_from_names_tmp ( name text ) ;'
  ActiveRecord::Base.connection.execute(sql)

  MiAttempt.all.each do |mi_attempt|
    #MiAttempt.where(:id => @failed_mis).each do |mi_attempt|
    next if mi_attempt.gene.mgi_accession_id.nil?

    if mi_attempt.has_status? :gtc and ! mi_attempt.has_status? :abt and mi_attempt.allele_id.to_i > 0 and mi_attempt.report_to_public
      solr_doc = {}
      SolrUpdate::DocFactory.set_order_from_details(mi_attempt, solr_doc)
      old = solr_doc

      next if old.empty? || old['order_from_names'].empty?

      old = old['order_from_names'].sort.uniq

      rows = ActiveRecord::Base.connection.execute("select * from solr_get_mi_order_from_names(#{mi_attempt.id})")

      # pp rows.first

      count = 0
      new = ''
      rows.each do |row|
        new = row['solr_get_mi_order_from_names'].split ';'
        count += 1
      end

      raise "#### invalid count detected!".red if count != 1

      old = old.to_a.sort
      new = new.to_a.sort

      if old.size != new.size
        puts "#### size error: #{mi_attempt.id}: (#{old.size}/#{new.size}) - (#{old}/#{new})".red
        @failed_count += 1
      elsif old != new
        puts "#### error: #{mi_attempt.id}: (#{old}/#{new})".red
        @failed_count += 1
      end

      @count += 1
      #break if @count >= 10
      #break
    end
  end
end

def test_mi_attempt_order_from_urls
  @count = 0
  @failed_count = 0

  sql = 'CREATE temp table solr_get_mi_order_from_urls_tmp ( url text ) ;'
  ActiveRecord::Base.connection.execute(sql)

  MiAttempt.all.each do |mi_attempt|
    #MiAttempt.where(:id => @failed_mis).each do |mi_attempt|
    next if mi_attempt.gene.mgi_accession_id.nil?

    if mi_attempt.has_status? :gtc and ! mi_attempt.has_status? :abt and mi_attempt.allele_id.to_i > 0 and mi_attempt.report_to_public
      solr_doc = {}
      SolrUpdate::DocFactory.set_order_from_details(mi_attempt, solr_doc)
      old = solr_doc

      next if old.empty? || old['order_from_urls'].empty?

      old = old['order_from_urls'].sort.uniq

      rows = ActiveRecord::Base.connection.execute("select * from solr_get_mi_order_from_urls(#{mi_attempt.id})")

      # pp rows.first

      count = 0
      new = ''
      rows.each do |row|
        new = row['solr_get_mi_order_from_urls'].split ';'
        count += 1
      end

      raise "#### invalid count detected!".red if count != 1

      old = old.to_a.sort
      new = new.to_a.sort

      if old.size != new.size
        puts "#### size error: #{mi_attempt.id}: (#{old.size}/#{new.size}) - (#{old}/#{new})".red
        @failed_count += 1
      elsif old != new
        puts "#### error: #{mi_attempt.id}: (#{old}/#{new})".red
        @failed_count += 1
      end

      @count += 1
      #break if @count >= 100
      #break
    end
  end
end

def test_get_best_status_pa(cre_required)
  @count = 0
  @failed_count = 0

  MiAttempt.all.each do |mi_attempt|
    #MiAttempt.where(:id => @failed_mis).each do |mi_attempt|
    next if mi_attempt.gene.mgi_accession_id.nil?

    if mi_attempt.has_status? :gtc and ! mi_attempt.has_status? :abt and mi_attempt.allele_id.to_i > 0 and mi_attempt.report_to_public
      old = mi_attempt.relevant_phenotype_attempt_status(cre_required)

      next if ! old
      old = old[:name]

      rows = ActiveRecord::Base.connection.execute("select * from get_best_status_pa(#{mi_attempt.id}, #{cre_required})")

      count = 0
      new = ''
      rows.each do |row|
        new = row['get_best_status_pa']
        count += 1
      end

      raise "#### invalid count detected!".red if count != 1

      if old != new
        puts "#### error: #{mi_attempt.id}: (#{old}/#{new})".red
        @failed_count += 1
      end

      @count += 1
      #break if @count >= 100
      #break
    end
  end
end

#{"id"=>"7916",
# "product_type"=>"Mouse",
# "type"=>"mi_attempt",
# "colony_name"=>"Il12rb1 <EPD0847_4_B02>",
# "marker_symbol"=>"Il12rb1",
# "es_cell_name"=>"EPD0847_4_B02",
# "allele_id"=>"24745",
# "mgi_accession_id"=>"MGI:104579",
# "production_centre"=>"BCM",
# "strain"=>"C57BL/6N",
# "genbank_file_url"=>
#  "http://localhost:3000/targ_rep/alleles/24745/escell-clone-genbank-file",
# "allele_image_url"=>
#  "http://localhost:3000/targ_rep/alleles/24745/allele-image",
# "simple_allele_image_url"=>
#  "http://localhost:3000/targ_rep/alleles/24745/allele-image?simple=true",
# "allele_type"=>"Conditional Ready",
# "project_ids"=>"82297",
# "current_pa_status"=>"",
# "allele_name"=>"Il12rb1<sup>tm1a(KOMP)Wtsi</sup>",
# "order_from_names"=>nil,
# "order_from_urls"=>nil,
# "best_status_pa_cre_ex_not_required"=>"",
# "best_status_pa_cre_ex_required"=>"Cre Excision Started"}

def test_solr_mi_attempts
  @count = 0
  @failed_count = 0
  hash = {}
  count = 0

  mi_attempts = ActiveRecord::Base.connection.execute("select * from solr_mi_attempts")

  ints = %W{id}
  splits = %W{project_ids order_from_names order_from_urls}

  mi_attempts.each do |mi_attempt|
    splits.each do |split|
      mi_attempt[split] = mi_attempt[split].to_s.split(';')
    end

    ints.each do |i|
      mi_attempt[i] = mi_attempt[i].to_i
    end

    mi_attempt.keys.each do |key|
      mi_attempt.delete key if mi_attempt[key].nil?
    end

    hash[mi_attempt['id'].to_i] = mi_attempt.clone

    count += 1
  end

  MiAttempt.all.each do |mi_attempt|
    failed = false

    next if mi_attempt.gene.mgi_accession_id.nil?

    if mi_attempt.has_status? :gtc and ! mi_attempt.has_status? :abt and mi_attempt.allele_id.to_i > 0 and mi_attempt.report_to_public
      docs = SolrUpdate::DocFactory.create_for_mi_attempt(mi_attempt)
      doc = docs.first

      next if ! doc

      doc.keys.each do |key|
        doc.delete key if doc[key].nil?     #|| (doc[key].size == 1 && doc[key].first.to_s.empty?)
      end

      old = doc

      new = hash[doc['id'].to_i]

      if ! new
        puts "#### #{mi_attempt.id}: cannot be found!".red
        failed = true
      end

      if old.keys.size != new.keys.size
        puts "#### #{mi_attempt.id}: size error: (#{old.keys.size}/#{new.keys.size})".red
        failed = true
      end

      keys = old.keys - splits

      keys.each do |key|
        if old[key].to_s != new[key].to_s
          puts "#### #{mi_attempt.id}: '#{key}': compare error: (#{old[key]}/#{new[key]})".red
          failed = true
        end
      end

      splits.each do |key|
        if old[key].size == 1 && old[key].first.to_s.empty?
          old[key] = []
        end

        old[key] = old[key].to_a.sort.uniq
        new[key] = new[key].to_a.sort.uniq
        if old[key].to_s != new[key].to_s
          puts "#### #{mi_attempt.id}: '#{key}': compare error: (#{old[key].to_s}/#{new[key].to_s})".red
          failed = true
        end
      end

      @count += 1
      @failed_count += 1 if failed
      #break if @count >= 10
      #break

      if failed
        pp old
        pp new
        break
      end
    end
  end

  puts "#### count error: (#{count}/#{@count})".red if count != @count
end

if enabler['test_mi_attempt_allele_symbol']
  test_mi_attempt_allele_symbol

  puts "#### done test_mi_attempt_allele_symbol: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_mi_attempt_allele_symbol: (#{@count})".green if @failed_count == 0
end

if enabler['test_mi_attempt_order_from_names']
  test_mi_attempt_order_from_names

  puts "#### done test_mi_attempt_order_from_names: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_mi_attempt_order_from_names: (#{@count})".green if @failed_count == 0
end

if enabler['test_mi_attempt_order_from_urls']
  test_mi_attempt_order_from_urls

  puts "#### done test_mi_attempt_order_from_urls: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_mi_attempt_order_from_urls: (#{@count})".green if @failed_count == 0
end

if enabler['test_get_best_status_pa']
  test_get_best_status_pa true

  puts "#### done test_get_best_status_pa: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_get_best_status_pa: (#{@count})".green if @failed_count == 0

  test_get_best_status_pa false

  puts "#### done test_get_best_status_pa: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_get_best_status_pa: (#{@count})".green if @failed_count == 0
end

if enabler['test_solr_mi_attempts']
  test_solr_mi_attempts

  puts "#### done test_solr_mi_attempts: (#{@failed_count}/#{@count})".red if @failed_count > 0
  puts "#### done test_solr_mi_attempts: (#{@count})".green if @failed_count == 0
end
