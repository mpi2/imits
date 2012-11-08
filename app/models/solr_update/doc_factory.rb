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

    if phenotype_attempt.mouse_allele_type == 'b'
      solr_doc['allele_type'] = 'Cre Excised Conditional Ready'
    elsif phenotype_attempt.mouse_allele_type == '.1'
      solr_doc['allele_type'] = 'Cre Excised Deletion'
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

  #def self.set_order_from_details_old(object, solr_doc)
  #  if Consortium.komp2.include? object.consortium
  #    solr_doc['order_from_name'] = 'KOMP'
  #    project_id = object.es_cell.ikmc_project_id
  #    if project_id.nil?
  #      solr_doc['order_from_url'] = "http://www.komp.org/"
  #    else
  #      if ! project_id.match(/^VG/)
  #        project_id = 'CSD' + project_id
  #      end
  #
  #      solr_doc['order_from_url'] = "http://www.komp.org/geneinfo.php?project=#{project_id}"
  #    end
  #
  #  elsif ['Phenomin', 'Helmholtz GMC', 'Monterotondo', 'MRC'].include? object.consortium.name
  #    solr_doc['order_from_name'] = 'EMMA'
  #    solr_doc['order_from_url'] = "http://www.emmanet.org/mutant_types.php?keyword=#{object.gene.marker_symbol}"
  #
  #  elsif ['MGP', 'MGP Legacy'].include? object.consortium.name
  #    if object.distribution_centres.all.find {|ds| ds.is_distributed_by_emma? }
  #      solr_doc['order_from_name'] = 'EMMA'
  #      solr_doc['order_from_url'] = "http://www.emmanet.org/mutant_types.php?keyword=#{object.gene.marker_symbol}"
  #    else
  #      solr_doc['order_from_name'] = 'WTSI'
  #      solr_doc['order_from_url'] = "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{object.gene.marker_symbol}"
  #    end
  #  end
  #end

  def self.set_order_from_details(object, solr_doc, config = nil)
    # get config yml
    # find target
    # raise on fail
    # build from config
    # loop over centres

    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

  #  pp config

    solr_doc['order_from_names'] ||= []
    solr_doc['order_from_urls'] ||= []

    object.distribution_centres.each do |distribution_centre|

      centre_name = distribution_centre.centre.name

      next if ! config.has_key? centre_name

      details = config[centre_name]
      details = config['EMMA'] if distribution_centre.is_distributed_by_emma

      project_id = object.es_cell.ikmc_project_id
      marker_symbol = object.gene.marker_symbol
      order_from_name = centre_name
      order_from_name = 'EMMA' if distribution_centre.is_distributed_by_emma

      ##check for emma
      #if distribution_centre.is_distributed_by_emma
      # # solr_doc['orders'].push({:order_from_name => 'EMMA', :order_from_url => config['EMMA'][:preferred]})
      # # next
      # details = config['EMMA']
      #end
      #puts "#### project_id: #{project_id}"
      #puts "#### marker_symbol: #{marker_symbol}"

      order_from_url = details[:default]
      order_from_url = details[:preferred].gsub(/PROJECT_ID/, project_id) if /PROJECT_ID/ =~ details[:preferred] && project_id
      order_from_url = details[:preferred].gsub(/MARKER_SYMBOL/, marker_symbol) if /MARKER_SYMBOL/ =~ details[:preferred] && marker_symbol

#      solr_doc['orders'].push({:order_from_name => order_from_name, :order_from_url => order_from_url}) if order_from_url

      solr_doc['order_from_names'].push order_from_name if order_from_url
      solr_doc['order_from_urls'].push order_from_url if order_from_url
    end
  end

end
