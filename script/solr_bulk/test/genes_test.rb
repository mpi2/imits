#!/usr/bin/env ruby

require 'pp'
require 'color'

@count = 0
@failed_count = 0

enabler = {
  'whatever' => true
}

#solr_ikmc_projects_details_agg_es_cells.projects AS project_ids,
#solr_ikmc_projects_details_agg_es_cells.statuses AS project_statuses,
#solr_ikmc_projects_details_agg_es_cells.pipelines AS project_pipelines,
#
#solr_ikmc_projects_details_agg_vectors.projects AS vector_project_ids,
#solr_ikmc_projects_details_agg_vectors.statuses AS vector_project_statuses,

#{"id"=>29,
# "type"=>"gene",
# "allele_id"=>"-1",
# "mgi_accession_id"=>"MGI:1916023",
# "consortium"=>"MGP Legacy",
# "production_centre"=>"WTSI",
# "marker_symbol"=>"Zc3hc1",
# "project_ids"=>["27841", "79887", "89610"],
# "project_statuses"=>
#  ["Mice - Genotype confirmed", "Vector Complete", "Vector Complete"],
# "marker_type"=>"Gene",
# "vector_project_ids"=>["79887", "89610"],
# "vector_project_statuses"=>["Vector Complete", "Vector Complete"],
# "project_pipelines"=>["KOMP-CSD", "KOMP-CSD", "KOMP-CSD"],
# "status"=>"Genotype confirmed",
# "effective_date"=>Sun, 20 Jul 2008 00:00:00 UTC +00:00}

def test_solr_genes
  @count = 0
  @failed_count = 0
  count = 0

  hash = {}

  genes = ActiveRecord::Base.connection.execute("select * from solr_genes")

  splits = %W{project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}

  genes.each do |gene|
    splits.each do |split|
      gene[split] = gene[split].to_s.split(';')
    end
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

  Gene.order(:id).each do |gene|
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

    #splits = %W{project_ids project_statuses project_pipelines vector_project_ids vector_project_statuses}
    splits = %W{vector_project_statuses}

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




    @failed_count += 1 if failed
    @count += 1
    break if @count >= 1000
  end

  puts "#### count error: (#{count}/#{@count})".red if count != @count
end

test_solr_genes

puts "#### done test_solr_genes: (#{@failed_count}/#{@count})".red if @failed_count > 0
puts "#### done test_solr_genes: (#{@count})".green if @failed_count == 0
