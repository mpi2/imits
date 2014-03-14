#!/usr/bin/env ruby

require 'pp'
require 'color'

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
10515, 10999, 11797, 11886, 12487, 13115, 13494, 14142, 14202, 14765
]

#enabler = {
#  'whatever' => true
#}

LIMIT = 10000
STARTER = 20000
LESSTHANIGNORE = false

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

    #ohash[column] = Time.parse(line[column].to_s).strftime("%Y-%m-%d %H:%M:%S")

    dates.each do |i|
      gene[i] = Time.parse(gene[i].to_s).strftime("%Y-%m-%d %H:%M:%S") if gene[i].to_s.length > 0
    end

    gene['status'] = gene['status'].to_s.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase

    hash[gene['id'].to_i] = gene.clone

    #pp genes
    #break
    count += 1
  end

  #pp hash

  #puts "#### count: #{count}".blue

  #pp hash.first

  # pp hash

  # return

  puts "#### targets - #{LIMIT}...".blue if @gene_targets.size > 0 && STARTER < 1
  puts "#### all - #{LIMIT}...".blue if @gene_targets.size == 0 && STARTER < 1
  puts "#### start #{STARTER} - #{LIMIT}...".blue if @gene_targets.size == 0 && STARTER > 0

  genes = Gene.where(:id => @gene_targets) if @gene_targets.size > 0 && STARTER < 1
  genes = Gene.order(:id) if @gene_targets.size == 0 && STARTER < 1
  genes = Gene.where("id > #{STARTER}") if STARTER > 0 && @gene_targets.size == 0

  genes.each do |gene|
    failed = false
    docs = SolrUpdate::DocFactory.create_for_gene(gene)
    doc = docs.first
    # next if ! doc

    # pp doc
    #pp hash[doc['id']]

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

    #pp old
    #pp new

    splits = %W{project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    #splits = %W{vector_project_statuses}

    #slits.each do |split|
    #  old[split] = old[split].to_a.uniq
    #  new[split] = new[split].to_a.uniq
    #end

    splits.each do |split|
      old[split] = old[split].sort.uniq # TODO: lose uniq
      new[split] = new[split].sort.uniq

      if old[split].size != new[split].size
        puts "#### '#{split}': key count error 2: (#{old[split]}/#{new[split]})".red
        failed = true
        break
      end

      i = 0
      old[split].each do |item|
        if item != new[split][i]
          puts "#### split error 3: (#{item}/#{new[split][i]})".red
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

    #complex = %W{production_centre consortium effective_date status}
    complex = %W{production_centre consortium status}
    #complex = %W{production_centre consortium status}

    complex.each do |item|
      if old[item].to_s != new[item].to_s
        puts "#### #{old['id']}: '#{item}': (#{old[item]}/#{new[item]})".red
        failed = true
      end
    end

    if old['effective_date'].to_s.length > 0 || new['effective_date'].to_s.length > 0
      if old['effective_date'] != new['effective_date']
        error = "#{old['id']}: 'effective_date': (#{old['effective_date']}/#{new['effective_date']})"
        #datediff =  Time.parse(old['effective_date'].to_s) - Time.parse(new['effective_date'].to_s)
        datediff = (Time.parse(old['effective_date'].to_s) - Time.parse(new['effective_date'].to_s)).to_i.abs
        if datediff > 1000
          #if datediff > 86400
          #puts "\t#### datediff: #{datediff}".red
          @maxdatediff = datediff if @maxdatediff < datediff
          lessthan = Time.parse(new['effective_date'].to_s) < Time.parse(old['effective_date'].to_s)
        #  if ! LESSTHANIGNORE
        #    if ! lessthan
            puts "#### #{error} - diff: #{datediff} - less: #{lessthan}".red
            # puts "#### #{old['consortium']}/#{old['production_centre']}/#{old['status']} - #{new['consortium']}/#{new['production_centre']}/#{new['status']}".red
            failed = true
        #  end
        #  end
        end
      end
    end

    #@failed_genes.push({ 'id' => old['id'], 'marker_symbol' => old['marker_symbol'] }) if failed
    @failed_genes.push old['id'] if failed

    @failed_count += 1 if failed
    @count += 1
    break if LIMIT > -1 && @count >= LIMIT

    #pp old
    #pp new
  end

  puts "#### count error: (#{count}/#{@count})".red if count != @count
end

test_solr_genes

puts "#### done test_solr_genes: (#{@failed_count}/#{@count})".red if @failed_count > 0
puts "#### done test_solr_genes: (#{@count})".green if @failed_count == 0

puts "#### max date diff: #{@maxdatediff}"
pp @failed_genes if @failed_genes.size > 0 && @gene_targets.size == 0
