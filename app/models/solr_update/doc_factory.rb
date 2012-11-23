require 'pp'

class SolrUpdate::DocFactory
  extend SolrUpdate::Util

  def self.create(reference)
    case reference['type']

    when 'mi_attempt' then
      return create_for_mi_attempt(MiAttempt.find(reference['id']))

    when 'phenotype_attempt' then
      return create_for_phenotype_attempt(PhenotypeAttempt.find(reference['id']))

    else
      raise 'unknown type'
    end
  end

  def self.create_for_mi_attempt(mi_attempt)
    solr_doc = {
      'id' => mi_attempt.id,
      'product_type' => 'Mouse',
      'type' => 'mi_attempt'
    }

    if mi_attempt.gene.mgi_accession_id
      solr_doc['mgi_accession_id'] = mi_attempt.gene.mgi_accession_id
    end

    solr_doc['allele_id'] = mi_attempt.allele_id

    if mi_attempt.mouse_allele_type == 'e'
      solr_doc['allele_type'] = 'Targeted Non Conditional'
    else
      if mi_attempt.es_cell.mutation_subtype
        solr_doc['allele_type'] = mi_attempt.es_cell.mutation_subtype.titleize
      end
    end

    if mi_attempt.colony_background_strain
      solr_doc['strain'] = mi_attempt.colony_background_strain.name
    end

    solr_doc['allele_name'] = mi_attempt.allele_symbol

    solr_doc['allele_image_url'] = allele_image_url(mi_attempt.allele_id)

    solr_doc['genbank_file_url'] = genbank_file_url(mi_attempt.allele_id)

    set_order_from_details(mi_attempt, solr_doc)

    return [solr_doc]
  end

  def self.create_for_phenotype_attempt(phenotype_attempt)
    solr_doc = {
      'id' => phenotype_attempt.id,
      'product_type' => 'Mouse',
      'type' => 'phenotype_attempt'
    }

    if phenotype_attempt.gene.mgi_accession_id
      solr_doc['mgi_accession_id'] = phenotype_attempt.gene.mgi_accession_id
    end

    #puts "#### create_for_phenotype_attempt:"
    #puts "#### phenotype_attempt:"
    #pp phenotype_attempt
    #puts "#### colony_background_strain:"
    #pp phenotype_attempt.colony_background_strain
    #puts "#### deleter_strain:"
    #pp phenotype_attempt.deleter_strain

    #puts "#### phenotype_attempt.mi_attempt.es_cell.allele_symbol_superscript_template:"
    #pp phenotype_attempt.mi_attempt.es_cell.allele_symbol_superscript_template

    #imits_development=# select distinct mouse_allele_type from phenotype_attempts;
    # mouse_allele_type
    #-------------------
    #
    # b
    # a
    # e
    # .1
    #(5 rows)

    #([^@\(]+)[@\(]

    #if phenotype_attempt.mouse_allele_type == 'b'
    #  solr_doc['allele_type'] = 'Cre-excised deletion (tm1b)'
    #elsif phenotype_attempt.mouse_allele_type == '.1'
    #  solr_doc['allele_type'] = 'Cre-excised deletion (tm1.1)'
    #end

    #if ['b', '.1'].include? phenotype_attempt.mouse_allele_type
    #  solr_doc['allele_type'] = "Cre-excised deletion (tm1#{phenotype_attempt.mouse_allele_type})"
    #end

    #if phenotype_attempt.mouse_allele_type == 'b'
    #  solr_doc['allele_type'] = 'Cre Excised Conditional Ready'
    #elsif phenotype_attempt.mouse_allele_type == '.1'
    #  solr_doc['allele_type'] = 'Cre Excised Deletion'
    #end

    allele_type = ''
    if phenotype_attempt.mouse_allele_symbol.nil?
      allele_type = phenotype_attempt.mi_attempt.allele_symbol
    else
      allele_type = phenotype_attempt.mouse_allele_symbol
    end

    puts "#### phenotype_attempt.mi_attempt.allele_symbol: #{phenotype_attempt.mi_attempt.allele_symbol}"
    puts "#### phenotype_attempt.mouse_allele_symbol: #{phenotype_attempt.mouse_allele_symbol}"
    puts "#### create_for_phenotype_attempt: allele_type: #{allele_type}"

    target = allele_type[/\>(.+)?\(/, 1]

    puts "#### create_for_phenotype_attempt: target: #{target}"

    if ['b', '.1'].include? phenotype_attempt.mouse_allele_type
      solr_doc['allele_type'] = "Cre-excised deletion (#{target})"
    end





    solr_doc['allele_id'] = phenotype_attempt.allele_id

    if phenotype_attempt.colony_background_strain
      solr_doc['strain'] = phenotype_attempt.colony_background_strain.name
    end

    solr_doc['allele_name'] = phenotype_attempt.allele_symbol

    solr_doc['allele_image_url'] = allele_image_url(phenotype_attempt.allele_id, :cre => true)

    solr_doc['genbank_file_url'] = genbank_file_url(phenotype_attempt.allele_id, :cre => true)

    set_order_from_details(phenotype_attempt, solr_doc)

    return [solr_doc]
  end

  def self.set_order_from_details(object, solr_doc, config = nil)
    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    raise "Expecting to find KOMP in distribution centre config" if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config" if ! config.has_key? 'EMMA'

    solr_doc['order_from_names'] ||= []
    solr_doc['order_from_urls'] ||= []

    object.distribution_centres.each do |distribution_centre|
      centre_name = distribution_centre.centre.name

      next if ! ['UCD', 'EMMA'].include?(centre_name) && ! config.has_key?(centre_name)

      current_time = Time.now

      if distribution_centre.start_date
        start_date = distribution_centre.start_date
      else
        start_date = current_time
      end

      current = current_time

      if distribution_centre.end_date
        end_date = distribution_centre.end_date
      else
        end_date = current_time
      end

      range = start_date.to_time..end_date.to_time

      next if ! range.cover?(current)

      centre_name = 'KOMP' if centre_name == 'UCD'
      centre_name = 'EMMA' if distribution_centre.is_distributed_by_emma?
      details = config[centre_name]

      next if details[:preferred].length == 0

      project_id = object.es_cell.ikmc_project_id
      marker_symbol = object.gene.marker_symbol
      order_from_name = centre_name

      order_from_url = details[:default]

      if project_id && /PROJECT_ID/ =~ details[:preferred]
        order_from_url = details[:preferred].gsub(/PROJECT_ID/, project_id)
      end

      if marker_symbol && /MARKER_SYMBOL/ =~ details[:preferred]
        order_from_url = details[:preferred].gsub(/MARKER_SYMBOL/, marker_symbol)
      end

      if order_from_url
        solr_doc['order_from_names'].push order_from_name
        solr_doc['order_from_urls'].push order_from_url
      end

    end
  end

end
