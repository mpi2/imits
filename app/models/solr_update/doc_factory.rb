
#require 'pp'

class SolrUpdate::DocFactory
  extend SolrUpdate::Util

  def self.create(reference)
    case reference['type']

    when 'mi_attempt' then
      return create_for_mi_attempt(MiAttempt.find(reference['id']))

    when 'phenotype_attempt' then
      return create_for_phenotype_attempt(PhenotypeAttempt.find(reference['id']))

    when 'allele' then
      return create_for_allele(TargRep::TargetedAllele.find(reference['id']))

    when 'gene' then
      return create_for_gene(Gene.find(reference['id']))

    else
      raise 'unknown type'
    end
  end

  #def self.get_best_phenotype_attempt(mi_attempt)
  #  pt = mi_attempt.phenotype_attempts.order('is_active desc, created_at desc').first
  #
  #  #mi_attempt.phenotype_attempts.each do |phenotype_attempt|
  #  #end
  #
  #  if pt
  #    pheno_status_list = {}
  #    mi_dates = pt.reportable_statuses_with_latest_dates
  #
  #    mi_dates.each do |name, date|
  #      pheno_status_list["#{name}"] = date.to_s
  #    end
  #
  #    s = pt.status.name
  #    d = pheno_status_list[s]
  #  end
  #end

  def self.relevant_phenotype_attempt_status(mi_attempt)

    #puts"\n\n\n#### mi_attempt.phenotype_attempts:"
    #pp mi_attempt.phenotype_attempts
    #puts"#### \n\n\n"

    return nil if ! mi_attempt.phenotype_attempts || mi_attempt.phenotype_attempts.size == 0

    selected_status = {}

    mi_attempt.phenotype_attempts.each do |phenotype_attempt|

      if selected_status.empty?
        status = phenotype_attempt.status_stamps.first.status
        selected_status = {
          :name => status.name,
          :order_by => status.order_by,
          :cre_excision_required => phenotype_attempt.cre_excision_required
        }
      end

      phenotype_attempt.status_stamps.each do |status_stamp|

        #puts "\n\n\n#### status_stamp:"
        #pp status_stamp
        #puts "####\n\n\n"
        #
        #puts "\n\n\n#### selected_status:"
        #pp selected_status
        #puts "####\n\n\n"

        if status_stamp.status[:order_by] > selected_status[:order_by]
          selected_status = {
            :name => status_stamp.status.name,
            :order_by => status_stamp.status.order_by,
            :cre_excision_required => phenotype_attempt.cre_excision_required
          }
        end
      end

    end

    selected_status.empty? ? nil : selected_status
  end

#        elsif this_status[:order_by] > @selected_status[:order_by]

  def self.create_for_mi_attempt(mi_attempt)
    solr_doc = {
      'id' => mi_attempt.id,
      'product_type' => 'Mouse',
      'type' => 'mi_attempt',
      'best_status_pa_cre_ex_not_required' => '',
      'best_status_pa_cre_ex_required' => '',
      'current_pa_status' => ''
    }

    #1) When there was a genotype confirmed mouse (doctype = mouse),
    #a) Augment the document to indicate the best status of any PA for that mouse which had cre_ex_required => false.
    #b) Also augment the doc to indicate the best status of any PA for that mouse which had cre_ex_required => true - this will be redundant to the next part.

    #2) When there was a cre-ex PA (doctype = mouse), augment it to indicate the current status of this particular PA (ie whether the PA is phenotype-started etc).

    #best_pa_status = relevant_phenotype_attempt_status(mi_attempt)
    best_pa_status = mi_attempt.relevant_phenotype_attempt_status

    if best_pa_status
      if best_pa_status[:cre_excision_required]
        solr_doc['best_status_pa_cre_ex_required'] = best_pa_status[:name]
      else
        solr_doc['best_status_pa_cre_ex_not_required'] = best_pa_status[:name]
      end
    end

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
      'type' => 'phenotype_attempt',
      'best_status_pa_cre_ex_not_required' => '',
      'best_status_pa_cre_ex_required' => '',
      'current_pa_status' => ''
    }

    #1) When there was a genotype confirmed mouse (doctype = mouse),
    #a) Augment the document to indicate the best status of any PA for that mouse which had cre_ex_required => false.
    #b) Also augment the doc to indicate the best status of any PA for that mouse which had cre_ex_required => true - this will be redundant to the next part.

    #2) When there was a cre-ex PA (doctype = mouse), augment it to indicate the current status of this particular PA (ie whether the PA is phenotype-started etc).

    #s = phenotype_attempt.mi_plan.gene.relevant_status
    #status = s[:status].humanize

    #if phenotype_attempt.cre_excision_required
    #  solr_doc['best_status_pa_cre_ex_required'] = phenotype_attempt.status.name
    #  #solr_doc['best_status_pa_cre_ex_required'] = status
    #else
    #  solr_doc['best_status_pa_cre_ex_not_required'] = phenotype_attempt.status.name
    #  #solr_doc['best_status_pa_cre_ex_not_required'] = status
    #end

    #solr_doc['current_pa_status'] = solr_doc['best_status_pa_cre_ex_required']
    solr_doc['current_pa_status'] = phenotype_attempt.status.name

    #puts "\n\n\n#### phenotype_attempt:"
    #pp phenotype_attempt
    #pp phenotype_attempt.status
    #puts "####\n\n\n"

    if phenotype_attempt.gene.mgi_accession_id
      solr_doc['mgi_accession_id'] = phenotype_attempt.gene.mgi_accession_id
    end

    allele_type = ''
    if phenotype_attempt.mouse_allele_symbol.nil?
      allele_type = phenotype_attempt.mi_attempt.allele_symbol
    else
      allele_type = phenotype_attempt.mouse_allele_symbol
    end

    target = allele_type[/\>(.+)?\(/, 1]
    target = target ? " (#{target})" : ''

    solr_doc['allele_type'] = "Cre-excised deletion#{target}"

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
      centre_name = distribution_centre.distribution_network if distribution_centre.distribution_network
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

  def self.create_for_allele(allele)
    marker_symbol = allele.gene.marker_symbol
    docs = allele.es_cells.unique_public_info.map do |es_cell_info|
      order_from_info = calculate_order_from_info(es_cell_info.merge(:allele => allele))



      #3) When we had an ES-cell (doctype = es cell), augment it to indicate if any mouse production was in progress on that 'class' of ES cells.
      #This last one is possibly tricky - can skip if needed.

      #puts "\n\n\n#### allele:"
      #pp allele
      #puts "####\n\n\n"

      s = allele.gene.relevant_status
      status = s[:status].to_s.humanize

      {
        'type' => 'allele',
        'id' => allele.id,
        'product_type' => 'ES Cell',
        'allele_type' => allele.mutation_type.name.titleize,
        'allele_id' => allele.id,
        'mgi_accession_id' => allele.mgi_accession_id,
        'strain' => es_cell_info[:strain],
        'allele_name' => "#{marker_symbol}<sup>#{es_cell_info[:mgi_allele_symbol_superscript]}</sup>",
        'allele_image_url' => allele_image_url(allele.id),
        'genbank_file_url' => genbank_file_url(allele.id),
        'order_from_urls' => [order_from_info[:url]],
        'order_from_names' => [order_from_info[:name]],
        'production_in_progress' => status
      }
    end

    return docs
  end

  def self.calculate_order_from_info(data)
    if(['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].include?(data[:pipeline]))
      return {:url => 'http://www.eummcr.org/order.php', :name => 'EUMMCR'}

    elsif(['KOMP-CSD', 'KOMP-Regeneron'].include?(data[:pipeline]))
      if ! data[:ikmc_project_id].blank?
        if data[:ikmc_project_id].match(/^VG/)
          project = data[:ikmc_project_id]
        else
          project = 'CSD' + data[:ikmc_project_id]
        end
        url = "http://www.komp.org/geneinfo.php?project=#{project}"
      else
        url = "http://www.komp.org/"
      end

      return {:url => url, :name => 'KOMP'}

    elsif(['mirKO', 'Sanger MGP'].include?(data[:pipeline]))
      marker_symbol = data[:allele].gene.marker_symbol
      return {:url => "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{marker_symbol}", :name => 'Wtsi'}

    elsif('NorCOMM' == data[:pipeline])
      return {:url => 'http://www.phenogenomics.ca/services/cmmr/escell_services.html', :name => 'NorCOMM'}

    else
      raise "Pipeline not recognized"
    end
  end

  def self.create_for_gene(gene)
    solr_doc = {
      'id' => gene.id,
      'type' => 'gene',
      'allele_id' => '-1',
      'mgi_accession_id' => ! gene.mgi_accession_id.blank? ? gene.mgi_accession_id : 'unknown',
      'consortium' => '',
      'production_centre' => ''
    }

    plan = gene.relevant_plan

    if plan
      solr_doc['consortium'] = plan.consortium.name if plan.consortium
      solr_doc['production_centre'] = plan.production_centre.name if plan.production_centre
    end

    s = gene.relevant_status

    solr_doc['status'] = s[:status].to_s.humanize
    solr_doc['effective_date'] = s[:date]

    return [solr_doc]
  end

end
