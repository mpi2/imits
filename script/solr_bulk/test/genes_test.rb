#!/usr/bin/env ruby

require 'pp'
require 'color'

class GenesTest
  LIMIT = 1000
  STARTER = -1
  BATCH_SIZE = 1000
  IGNORE = []

  def initialize
    @count = 0
    @failed_count = 0
    @failed_genes = []
    @maxdatediff = 0
    @gene_targets = []
    @gene_targets2 = [
      195,
      828,
      885,
      1168,
      1169,
      1375,
      1731,
      1976,
      2045,
      2066,
      2085,
      2100,
      2114,
      2207,
      2217,
      2239,
      2242,
      2262,
      2268,
      2347,
      2368,
      2408,
      2434,
      2437,
      2542,
      3069,
      3152,
      4345,
      5704,
      5921,
      6034,
      6169,
      6178,
      6416,
      7251,
      7916,
      8257,
      8267,
      9001,
      9586,
      9691,
      10515,
      10999,
      11797,
      11886,
      12487,
      13115,
      13494,
      14142,
      14202,
      14765,
      15890,
      16018,
      17083,
      18509,
      19843,
      19898
    ]
  end

  def test_solr_genes
    @count = 0
    @failed_count = 0
    count = 0

    ints = %W{id}
    dates = %W{effective_date}
    simples = %W{type mgi_accession_id marker_symbol marker_type allele_id}
    complex = %W{production_centre consortium effective_date status}

    hash = {}

    genes = ActiveRecord::Base.connection.execute("select * from solr_genes")

    splits = %W{project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}

    genes.each do |gene|
      splits.each do |split|
        gene[split] = gene[split].to_s.split(';')
      end

      ints.each do |i|
        gene[i] = gene[i].to_i
      end

      dates.each do |i|
        gene[i] = Time.parse(gene[i].to_s).strftime("%Y-%m-%d %H:%M:%S") if gene[i].to_s.length > 0
      end

      gene['status'] = gene['status'].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase

      hash[gene['id'].to_i] = gene.clone
      count += 1
    end

    #Gene.where(:id => @gene_targets).each do |gene|
    Gene.find_each(:batch_size => BATCH_SIZE) do |gene|
      failed = false
      docs = SolrUpdate::DocFactory.create_for_gene(gene)
      doc = docs.first

      if ! hash.has_key?(doc['id'])
        puts "#### missing key: (#{doc['id']})".red
        @failed_count += 1
        next
      end

      diffkeys = doc.keys - hash[doc['id']].keys
      diffkeys = hash[doc['id']].keys - doc.keys if diffkeys.empty?

      old = doc
      new = hash[doc['id']]

      diffkeys.each do |key|
        old.delete key
        new.delete key
      end

      if old.keys.size != new.keys.size
        puts "#### key count error: (#{old.keys.size}/#{new.keys.size})".red
        pp diffkeys
        failed = true
      end

      splits = %W{project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}

      splits.each do |split|
        old[split] = old[split].sort.uniq # TODO: lose uniq
        new[split] = new[split].sort.uniq

        if old[split].size != new[split].size
          puts "#### #{old['id']}: '#{split}': key count error 2: (#{old[split]}/#{new[split]})".red
          failed = true
          break
        end

        i = 0
        old[split].each do |item|
          if item != new[split][i]
            puts "#### #{old['id']}: split error 3: (#{item}/#{new[split][i]})".red
            failed = true
          end
          i += 1
        end
      end

      some = ints + simples
      some.each do |item|
        if old[item] != new[item]
          puts "#### #{old['id']}: '#{item}': (#{old[item]}/#{new[item]})".red
          failed = true
        end
      end

      old['effective_date'] = Time.parse(old['effective_date'].to_s).strftime("%Y-%m-%d %H:%M:%S") if old['effective_date'].to_s.length > 0
      old['status'] = old['status'].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase

      complex = %W{production_centre consortium status}

      complex.each do |item|
        if old[item].to_s != new[item].to_s
          puts "#### #{old['id']}: '#{item}': (#{old[item]}/#{new[item]})".red
          failed = true
        end
      end

      if ! IGNORE.include?('effective_date')
        if old['effective_date'].to_s.length > 0 || new['effective_date'].to_s.length > 0
          if old['effective_date'] != new['effective_date']
            error = "#{old['id']}: 'effective_date': (#{old['effective_date']}/#{new['effective_date']})"
            datediff = (Time.parse(old['effective_date'].to_s) - Time.parse(new['effective_date'].to_s)).to_i.abs
            if datediff > 1000
              @maxdatediff = datediff if @maxdatediff < datediff
              lessthan = Time.parse(new['effective_date'].to_s) < Time.parse(old['effective_date'].to_s)
              puts "#### #{error} - diff: #{datediff} - less: #{lessthan}".red
              failed = true
            end
          end
        end
      end

      @failed_genes.push old['id'] if failed

      @failed_count += 1 if failed
      @count += 1
      break if LIMIT > -1 && @count >= LIMIT
    end

    puts "#### count error: (#{count}/#{@count})".red if count != @count
  end

  def run
    puts "#### starting genes...".blue

    test_solr_genes

    puts "#### done test_solr_genes: (#{@failed_count}/#{@count})".red if @failed_count > 0
    puts "#### done test_solr_genes: (#{@count})".green if @failed_count == 0

    #puts "#### max date diff: #{@maxdatediff}"
    pp @failed_genes if @failed_genes.size > 0 && @gene_targets.size == 0
  end
end

GenesTest.new.run if File.basename($0) !~ /rake/
