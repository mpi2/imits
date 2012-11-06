class SolrUpdate::DocFactory
  extend SolrUpdate::Util

  def self.create(reference)
    case reference['type']

    when 'mi_attempt' then
      return create_for_mi_attempt(MiAttempt.find(reference['id']))

    when 'phenotype_attempt' then
      return create_for_phenotype_attempt(PhenotypeAttempt.find(reference['id']))

    when 'allele' then
      return create_for_allele(TargRep::Allele.find(reference['id']))

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

  def self.set_order_from_details(object, solr_doc)
    if Consortium.komp2.include? object.consortium
      solr_doc['order_from_name'] = 'KOMP'
      project_id = object.es_cell.ikmc_project_id
      if project_id.nil?
        solr_doc['order_from_url'] = "http://www.komp.org/"
      else
        if ! project_id.match(/^VG/)
          project_id = 'CSD' + project_id
        end

        solr_doc['order_from_url'] = "http://www.komp.org/geneinfo.php?project=#{project_id}"
      end

    elsif ['Phenomin', 'Helmholtz GMC', 'Monterotondo', 'MRC'].include? object.consortium.name
      solr_doc['order_from_name'] = 'EMMA'
      solr_doc['order_from_url'] = "http://www.emmanet.org/mutant_types.php?keyword=#{object.gene.marker_symbol}"

    elsif ['MGP', 'MGP Legacy'].include? object.consortium.name
      if object.distribution_centres.all.find {|ds| ds.is_distributed_by_emma? }
        solr_doc['order_from_name'] = 'EMMA'
        solr_doc['order_from_url'] = "http://www.emmanet.org/mutant_types.php?keyword=#{object.gene.marker_symbol}"
      else
        solr_doc['order_from_name'] = 'WTSI'
        solr_doc['order_from_url'] = "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{object.gene.marker_symbol}"
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
        'strain' => es_cell_info[:strain],
        'allele_name' => "#{marker_symbol}<sup>#{es_cell_info[:allele_symbol_superscript]}</sup>",
        'allele_image_url' => allele_image_url(allele.id),
        'genbank_file_url' => genbank_file_url(allele.id),
        'order_from_url' => order_from_info[:url],
        'order_from_name' => order_from_info[:name]
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

end
