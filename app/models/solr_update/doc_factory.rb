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


  def self.create_for_mi_attempt(mi_attempt)
    solr_doc = {
      'id' => mi_attempt.id,
      'product_type' => 'Mouse',
      'type' => 'mi_attempt',
      'best_status_pa_cre_ex_not_required' => '',
      'best_status_pa_cre_ex_required' => '',
      'current_pa_status' => '',
      'colony_name' => mi_attempt.colony_name,
      'project_ids' => [mi_attempt.es_cell.ikmc_project_id]
    }

    solr_doc['marker_symbol'] = mi_attempt.mi_plan.gene.marker_symbol

    solr_doc['es_cell_name'] = mi_attempt.es_cell.name

    solr_doc['production_centre'] = mi_attempt.production_centre.name

    best_pa_status_true = mi_attempt.relevant_phenotype_attempt_status(true)
    best_pa_status_false = mi_attempt.relevant_phenotype_attempt_status(false)

    solr_doc['best_status_pa_cre_ex_required'] = best_pa_status_true[:name] if best_pa_status_true
    solr_doc['best_status_pa_cre_ex_not_required'] = best_pa_status_false[:name] if best_pa_status_false

    if mi_attempt.gene.mgi_accession_id
      solr_doc['mgi_accession_id'] = mi_attempt.gene.mgi_accession_id
    end

    solr_doc['allele_id'] = mi_attempt.allele_id

    solr_doc['allele_type'] = mi_attempt.try(:es_cell).try(:allele).try(:mutation_type).try(:name).try(:titleize)
    solr_doc['allele_type'] = '' if ! solr_doc['allele_type']

    if mi_attempt.colony_background_strain
      solr_doc['strain'] = mi_attempt.colony_background_strain.name
    end

    solr_doc['allele_name'] = mi_attempt.allele_symbol

    solr_doc['allele_image_url'] = allele_image_url(mi_attempt.allele_id)
    solr_doc['simple_allele_image_url'] = allele_image_url(mi_attempt.allele_id, :simple => true)

    solr_doc['genbank_file_url'] = genbank_file_url(mi_attempt.allele_id)

    solr_doc['allele_has_issue']         = mi_attempt.es_cell.allele.has_issue
    solr_doc['allele_issue_description'] = mi_attempt.es_cell.allele.issue_description

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
      'current_pa_status' => '',
      'project_ids' => [phenotype_attempt.mi_attempt.es_cell.ikmc_project_id]
    }

    solr_doc['marker_symbol'] = phenotype_attempt.mi_plan.gene.marker_symbol

    solr_doc['colony_name'] = phenotype_attempt.colony_name
    solr_doc['parent_mi_attempt_colony_name'] = phenotype_attempt.mi_attempt.colony_name

    solr_doc['production_centre'] = phenotype_attempt.production_centre.name

    solr_doc['best_status_pa_cre_ex_required'] = phenotype_attempt.status.name if phenotype_attempt.cre_excision_required
    solr_doc['best_status_pa_cre_ex_not_required'] = phenotype_attempt.status.name if ! phenotype_attempt.cre_excision_required

    solr_doc['current_pa_status'] = phenotype_attempt.status.name

    if phenotype_attempt.gene.mgi_accession_id
      solr_doc['mgi_accession_id'] = phenotype_attempt.gene.mgi_accession_id
    end

    allele_type = ''
    if phenotype_attempt.mouse_allele_symbol.nil?
      allele_type = phenotype_attempt.mi_attempt.allele_symbol
    else
      allele_type = phenotype_attempt.mouse_allele_symbol
    end

    allele_type = '' if allele_type.nil?

    target = allele_type[/\>(.+)?\(/, 1]
    target = target ? " (#{target})" : ''

    solr_doc['allele_type'] = "Cre-excised deletion#{target}"

    solr_doc['allele_id'] = phenotype_attempt.allele_id

    if phenotype_attempt.colony_background_strain
      solr_doc['strain'] = phenotype_attempt.colony_background_strain.name
    end

    solr_doc['allele_name'] = phenotype_attempt.allele_symbol

    solr_doc['allele_image_url'] = allele_image_url(phenotype_attempt.allele_id, :cre => true)

    solr_doc['simple_allele_image_url'] = allele_image_url(phenotype_attempt.allele_id, :cre => true, :simple => true)

    solr_doc['genbank_file_url'] = genbank_file_url(phenotype_attempt.allele_id, :cre => true)

    solr_doc['allele_has_issue']         = phenotype_attempt.mi_attempt.es_cell.allele.has_issue
    solr_doc['allele_issue_description'] = phenotype_attempt.mi_attempt.es_cell.allele.issue_description

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
        'simple_allele_image_url' => allele_image_url(allele.id, :simple => true),
        'genbank_file_url' => genbank_file_url(allele.id),
        'order_from_urls' => [order_from_info[:url]],
        'order_from_names' => [order_from_info[:name]],
        'marker_symbol' => marker_symbol,
        'project_ids' => [es_cell_info[:ikmc_project_id]],
        'allele_has_issue'         => allele.has_issue,
        'allele_issue_description' => allele.issue_description
      }
    end

    return docs
  end

  def self.calculate_order_from_info(data)
    if(['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].include?(data[:pipeline]))
      mgi_accession_id = data[:allele].gene.mgi_accession_id
      return {:url => "http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells", :name => 'EUMMCR'}

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
      'production_centre' => '',
      'marker_symbol' => gene.marker_symbol,
      'project_ids' => [],
      'project_statuses' => [],
      'marker_type' => gene.marker_type
    }

    doc = add_project_details(gene)

    solr_doc.merge!(doc) #if doc && ! doc.empty?

    plan = gene.relevant_plan

    if plan
      solr_doc['consortium'] = plan.consortium.name if plan.consortium
      solr_doc['production_centre'] = plan.production_centre.name if plan.production_centre

      s = gene.relevant_status

      solr_doc['status'] = s[:status].to_s.humanize
      solr_doc['effective_date'] = s[:date]
    end

    return [solr_doc]
  end

  def self.add_project_details(gene)
    return nil if ! gene

    project_hash = {}
    vector_project_hash = {}
    pipeline_hash = {}
    solr_doc = {'project_ids' => [], 'project_statuses' => [], 'vector_project_ids' => [], 'vector_project_statuses' => [], 'project_pipelines' => []}

    gene.mi_attempts.each do |mi|
      key = mi.try(:es_cell).try(:ikmc_project).try(:name)
      value = mi.try(:es_cell).try(:ikmc_project).try(:status).try(:name)
      pipeline = mi.try(:es_cell).try(:ikmc_project).try(:pipeline).try(:name)
      next if ! key
      project_hash[key] = value
      pipeline_hash[key] = pipeline
    end

    gene.phenotype_attempts.each do |pa|
      key = pa.try(:mi_attempt).try(:es_cell).try(:ikmc_project).try(:name)
      value = pa.try(:mi_attempt).try(:es_cell).try(:ikmc_project).try(:status).try(:name)
      pipeline = pa.try(:mi_attempt).try(:es_cell).try(:ikmc_project).try(:pipeline).try(:name)
      next if ! key
      project_hash[key] = value
      pipeline_hash[key] = pipeline
    end

    gene.allele.each do |allele|
      allele.es_cells.unique_public_info.map do |es_cell_info|
        next if es_cell_info[:ikmc_project_name].empty?
        project_hash[es_cell_info[:ikmc_project_name]] = es_cell_info[:ikmc_project_status_name]
        pipeline_hash[es_cell_info[:ikmc_project_name]] = es_cell_info[:ikmc_project_pipeline]
      end
      allele.targeting_vectors.each do |tv|
        key = tv.try(:ikmc_project).try(:name)
        value = tv.try(:ikmc_project).try(:status).try(:name)
        pipeline = tv.try(:ikmc_project).try(:pipeline).try(:name)

        puts "#### 1 tv id: #{tv.id} - tv key: #{key} - value: #{value}"

        next if ! key
        project_hash[key] = value
        vector_project_hash[key] = value
        pipeline_hash[key] = pipeline
      end
    end

    pp project_hash

    #for each allele find all alleles of the same mutation type including itself. Then count the number of es_cells associated with these alleles. This will add anew attribute called es_cell_count to each allele model returned.
    sql = <<-EOF
      WITH allele_with_es_count AS (
        SELECT alleles1.id AS allele_id, targ_rep_es_cells.count AS es_cell_count
        FROM targ_rep_alleles AS alleles1
          JOIN targ_rep_alleles AS alleles2 ON alleles1.gene_id = alleles2.gene_id AND alleles1.mutation_type_id = alleles2.mutation_type_id AND alleles1.cassette = alleles2.cassette
          LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.allele_id = alleles2.id
        WHERE alleles2.gene_id = #{gene.id}
        GROUP BY alleles1.id)

      SELECT targ_rep_alleles.*, allele_with_es_count.es_cell_count FROM targ_rep_alleles JOIN allele_with_es_count ON allele_with_es_count.allele_id = targ_rep_alleles.id
    EOF
    alleles = TargRep::Allele.find_by_sql(sql)

   # puts sql

    alleles.each do |allele|
      puts "#### allele.es_cell_count.to_i: #{allele.es_cell_count.to_i}"
      next if allele.es_cell_count.to_i > 0
      allele.targeting_vectors.each do |tv|
        key = tv.try(:ikmc_project).try(:name)
        value = tv.try(:ikmc_project).try(:status).try(:name)

        puts "#### 2 tv id: #{tv.id} - tv key: #{key} - value: #{value}"

        next if ! key
        vector_project_hash[key] = value
      end
    end

    vector_project_hash.keys.each do |key|
      next if ! key
      solr_doc['vector_project_ids'].push key

      value = vector_project_hash[key]
      value = value ? value : 'unknown'

      solr_doc['vector_project_statuses'].push value
    end

    project_hash.keys.each do |key|
      next if ! key
      solr_doc['project_ids'].push key

      value = project_hash[key]
      value = value ? value : 'unknown'

      solr_doc['project_statuses'].push value

      pipeline = pipeline_hash[key]
      pipeline = pipeline ? pipeline : 'unknown'

      solr_doc['project_pipelines'].push pipeline
    end

    pp solr_doc

    solr_doc
  end

end
