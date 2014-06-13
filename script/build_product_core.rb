#!/usr/bin/env ruby

require 'pp'
require "digest/md5"
require "#{Rails.root}/script/solr_connect"

class BuildProductCore

  PLAN_SQL= <<-EOF
    SELECT mi_plans.id AS id,
       mi_plans.mutagenesis_via_crispr_cas9 AS crispr_plan,
       genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id,
       centres.name AS production_centre_name,
       mi_plans.ignore_available_mice AS ignore_available_mice
    FROM mi_plans
      JOIN centres ON centres.id = mi_plans.production_centre_id
      JOIN genes ON genes.id = mi_plans.gene_id
    WHERE mi_plans.report_to_public = true AND mi_plans.ignore_available_mice = false
  EOF


  ES_CELL_SQL= <<-EOF
    SELECT targ_rep_es_cells.id AS id, targ_rep_alleles.id AS allele_id, targ_rep_targeting_vectors AS targeting_vector_id,
      targ_rep_es_cells.name AS name,
      targ_rep_targeting_vectors.name AS targeting_vector_name,
      targ_rep_mutation_types.name AS mutation_type,
      targ_rep_es_cells.allele_type AS allele_type,
      targ_rep_es_cells.parental_cell_line AS parental_cell_line,
      targ_rep_alleles.cassette AS cassette,
      targ_rep_alleles.cassette_type AS cassette_type,
      targ_rep_alleles.backbone AS backbone,
      genes.marker_symbol AS marker_symbol,
      genes.mgi_accession_id AS mgi_accession_id,
      targ_rep_es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
      targ_rep_es_cells.mgi_allele_symbol_superscript AS allele_symbol_superscript,
      targ_rep_es_cells.report_to_public,
      targ_rep_es_cells.ikmc_project_foreign_id AS ikmc_project_foreign_id
    FROM targ_rep_es_cells
      JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
      JOIN genes ON genes.id = targ_rep_alleles.gene_id
      LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
      LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = targ_rep_es_cells.targeting_vector_id
  EOF

  DISTRIBUTION_CENTRES_SQL= <<-EOF
    SELECT all_dis_centres.mi_attempt_id, all_dis_centres.phenotype_attempt_id, array_agg(all_dis_centres.centre_name) AS centre_names, array_agg(all_dis_centres.distribution_network) AS distribution_networks, array_agg(all_dis_centres.start_date) AS start_dates, array_agg(all_dis_centres.end_date) AS end_dates
    FROM
    (
      SELECT mi_attempt_id AS mi_attempt_id, NULL AS phenotype_attempt_id, centres.name AS centre_name, distribution_network, start_date, end_date
      FROM mi_attempt_distribution_centres
      LEFT JOIN centres ON centres.id = mi_attempt_distribution_centres.centre_id
      UNION ALL
      SELECT NULL AS mi_attempt_id, phenotype_attempt_id AS phenotype_attempt_id, centres.name AS centre_name, distribution_network, start_date, end_date
      FROM phenotype_attempt_distribution_centres
      LEFT JOIN centres ON centres.id = phenotype_attempt_distribution_centres.centre_id
    ) AS all_dis_centres
    GROUP BY all_dis_centres.mi_attempt_id, all_dis_centres.phenotype_attempt_id
  EOF

  def self.es_cell_sql
    <<-EOF
      WITH es_cells AS (#{ES_CELL_SQL}),
      mouse_colonies AS (
        SELECT mi_attempts.es_cell_id AS es_cell_id, array_agg(mi_attempts.colony_name) AS list
        FROM mi_attempts
        GROUP BY mi_attempts.es_cell_id
      )

      SELECT es_cells.name AS es_cell_name,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.mutation_type AS mutation_type,
        es_cells.parental_cell_line AS parental_cell_line,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        es_cells.marker_symbol AS marker_symbol,
        es_cells.mgi_accession_id AS mgi_accession_id,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.allele_symbol_superscript AS allele_symbol_superscript,
        es_cells.allele_type AS es_cell_allele_type,
        mouse_colonies.list AS colonies,
        targ_rep_pipelines.name AS pipeline,
        targ_rep_ikmc_projects.name AS ikmc_project_id
      FROM es_cells
      LEFT JOIN mouse_colonies ON mouse_colonies.es_cell_id = es_cells.id
      LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = es_cells.ikmc_project_foreign_id
      LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      WHERE es_cells.report_to_public = true
      ORDER BY es_cell_name
    EOF
  end

  def self.targeting_vectors_sql
    #es_cell_names finds all es_cells created from the targeting vector and orders them by the allele_type (tm1, tm1a then tm1e).This will allow your to determine the targeting vector allele_type by selecting the first allele_type of the list
    <<-EOF
      WITH es_cell_names AS (
        SELECT es_cells.targeting_vector_id AS targeting_vector_id, array_agg(es_cells.mgi_allele_symbol_superscript) AS allele_names,array_agg(es_cells.allele_type) AS allele_types, array_agg(es_cells.name) AS list
        FROM
          (SELECT targ_rep_es_cells.*
          FROM targ_rep_es_cells
          ORDER BY targ_rep_es_cells.targeting_vector_id, targ_rep_es_cells.mgi_allele_symbol_superscript) AS es_cells
        GROUP BY es_cells.targeting_vector_id
      )

      SELECT genes.marker_symbol AS marker_symbol,
             genes.mgi_accession_id AS mgi_accession_id,
             targ_rep_mutation_types.code AS allele_type,
             targ_rep_alleles.cassette AS cassette,
             targ_rep_alleles.cassette_type AS cassette_type,
             targ_rep_alleles.backbone AS backbone,
             targ_rep_targeting_vectors.name AS vector_name,
             'Targeting Vector' AS vector_type,
             es_cell_names.list AS es_cell_names,
             es_cell_names.allele_names AS allele_names,
             es_cell_names.allele_types AS allele_types,
             targ_rep_pipelines.name AS pipeline,
             targ_rep_ikmc_projects.name AS ikmc_project_id
      FROM targ_rep_targeting_vectors
        JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
        LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
        JOIN genes ON genes.id = targ_rep_alleles.gene_id
        LEFT JOIN es_cell_names ON es_cell_names.targeting_vector_id = targ_rep_targeting_vectors.id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
        LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      WHERE targ_rep_targeting_vectors.report_to_public = true AND targ_rep_alleles.type = 'TargRep::TargetedAllele'
      ORDER BY targ_rep_targeting_vectors.name
    EOF
  end

  def self.intermediate_vectors_sql
    <<-EOF
      SELECT DISTINCT intermediate.marker_symbol AS marker_symbol, intermediate.mgi_accession_id AS mgi_accession_id, intermediate.vector_name AS vector_name,
        intermediate.mutation_type AS mutation_type,
        'Intermediate Vector' AS vector_type
      FROM
        (SELECT targ_rep_targeting_vectors.intermediate_vector AS vector_name, genes.marker_symbol AS marker_symbol, genes.mgi_accession_id AS mgi_accession_id, targ_rep_mutation_types.name AS mutation_type
          FROM targ_rep_targeting_vectors
            JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
            JOIN genes ON genes.id = targ_rep_alleles.gene_id
            LEFT JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
          WHERE targ_rep_targeting_vectors.intermediate_vector IS NOT NULL AND targ_rep_targeting_vectors.intermediate_vector != ''
          ) AS intermediate
      ORDER BY intermediate.vector_name
    EOF
  end

  def self.mice_lines_sql
    <<-EOF
      WITH plans AS (#{PLAN_SQL}), es_cells AS (#{ES_CELL_SQL}),
      distribution_centres AS (#{DISTRIBUTION_CENTRES_SQL})

      SELECT '' AS phenotype_attempt_mouse_allele_type,
        mi_attempts.mouse_allele_type AS mi_attempt_mouse_allele_type,
        es_cells.allele_type AS es_cell_allele_type,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.allele_symbol_superscript AS allele_symbol_superscript,
        plans.crispr_plan AS crispr_plan,
        mi_attempts.colony_name AS colony_name,
        mi_attempt_statuses.name AS mouse_status,
        es_cells.name AS es_cell_name,
        targ_rep_ikmc_projects.name AS ikmc_project_id,
        es_cells.targeting_vector_name AS vector_name,
        es_cells.mutation_type AS mutation_type,
        es_cells.cassette AS cassette,
        es_cells.cassette_type AS cassette_type,
        es_cells.backbone AS backbone,
        cb_strain.name AS background_colony_strain_name,
        del_strain.name AS deleter_strain_name,
        test_strain.name AS test_strain_name,
        distribution_centres.centre_names AS distribution_centre_names,
        distribution_centres.distribution_networks AS distribution_networks,
        distribution_centres.start_dates AS distribution_start_dates,
        distribution_centres.end_dates AS distribution_end_dates
      FROM (mi_attempts
        JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
        JOIN plans ON plans.id = mi_attempts.mi_plan_id
        )
        LEFT JOIN strains AS cb_strain ON cb_strain.id = mi_attempts.colony_background_strain_id
        LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mi_attempts.colony_background_strain_id
        LEFT JOIN strains AS test_strain ON test_strain.id = mi_attempts.colony_background_strain_id
        LEFT JOIN es_cells ON es_cells.id = mi_attempts.id
        LEFT JOIN distribution_centres On distribution_centres.mi_attempt_id = mi_attempts.id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = es_cells.ikmc_project_foreign_id
      WHERE mi_attempts.report_to_public = true

      UNION ALL

      SELECT mouse_allele_mods.mouse_allele_type AS phenotype_attempt_mouse_allele_type,
        mi_attempts.mouse_allele_type AS mi_attempt_mouse_allele_type,
        es_cells.allele_type AS es_cell_allele_type,
        plans.marker_symbol AS marker_symbol, plans.mgi_accession_id AS mgi_accession_id,
        plans.production_centre_name AS production_centre,
        es_cells.allele_id AS allele_id,
        es_cells.allele_symbol_superscript_template AS allele_symbol_superscript_template,
        es_cells.allele_symbol_superscript AS allele_symbol_superscript,
        false AS crispr_plan,
        mouse_allele_mods.colony_name AS colony_name,
        mouse_allele_mod_statuses.name AS mouse_status,
        '' AS es_cell_name,
        targ_rep_ikmc_projects.name AS ikmc_project_id,
        '' AS vector_name,
        '' AS mutation_type,
        '' AS cassette,
        '' AS cassette_type,
        '' AS backbone,
        cb_strain.name AS background_colony_strain_name,
        del_strain.name AS deleter_strain_name,
        '' AS test_strain_name,
        distribution_centres.centre_names AS distribution_centre_names,
        distribution_centres.distribution_networks AS distribution_networks,
        distribution_centres.start_dates AS distribution_start_dates,
        distribution_centres.end_dates AS distribution_end_dates
      FROM (mouse_allele_mods
        JOIN mouse_allele_mod_statuses ON mouse_allele_mod_statuses.id = mouse_allele_mods.status_id
        JOIN plans ON plans.id = mouse_allele_mods.mi_plan_id
        JOIN mi_attempts ON mi_attempts.id = mouse_allele_mods.mi_attempt_id
        LEFT JOIN es_cells ON mi_attempts.es_cell_id = es_cells.id)
        LEFT JOIN strains AS cb_strain ON cb_strain.id = mouse_allele_mods.colony_background_strain_id
        LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mouse_allele_mods.colony_background_strain_id
        LEFT JOIN distribution_centres ON distribution_centres.phenotype_attempt_id = mouse_allele_mods.phenotype_attempt_id
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = es_cells.ikmc_project_foreign_id
      WHERE mouse_allele_mods.report_to_public = true AND mouse_allele_mods.cre_excision = true
    EOF
  end



  def initialize
    @config = YAML.load_file("#{Rails.root}/script/build_allele2.yml")
    @solr_update = YAML.load_file("#{Rails.root}/config/solr_update.yml")

    @solr_url = @solr_update[Rails.env]['index_proxy']['product']
    puts "#### #{@solr_url}/admin/"
    @solr_user = @config['options']['SOLR_USER']
    @solr_password = @config['options']['SOLR_PASSWORD']
    @dataset_max_size = 80000
    @process_mice = true
    @process_es_cells = true
    @process_targeting_vectors = true
    @process_intermediate_vectors = true
  end

  def build_json data
    list = []
    data.each do |row|
      item = {'add' => {'doc' => row }}
      list.push item.to_json
    end
    return list
  end

  def delete_index type
    puts "deleting #{Time.now}"
    proxy = SolrConnect::Proxy.new(@solr_url)
    proxy.update({'delete' => {'query' => "type:#{type}"}}.to_json, @solr_user, @solr_password)
    proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
    puts "deleting complete #{Time.now}"
    nil
  end

  def send_to_index data
    puts "sending data #{Time.now}"
    proxy = SolrConnect::Proxy.new(@solr_url)
    proxy.update(data.join, @solr_user, @solr_password)
    proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
    puts "Commit Completed #{Time.now}"
    nil
  end


  def sent_to_index_in_batches datasets
    datasets.each do |data|
      puts "convert data into json format #{Time.now}"
      data = build_json(data)
      puts "finished converting data into json format #{Time.now}"
      puts "sending data set to solr #{Time.now}"
      send_to_index(data)
      puts "sending data set to sorl completed  #{Time.now}"
    end
    nil
  end

  def process_product_and_send_to_solr_core (step_no, product_type, product_sql, doc_creation_method_name)

    puts "#### step #{step_no} #{product_type} Products #{Time.now}"
    puts "#### step #{step_no}.1 Select #{Time.now}"

    rows = ActiveRecord::Base.connection.execute(product_sql)
    product_count = rows.count

    puts "count #{product_count}"
    puts "#### step #{step_no}.2 create json docs #{Time.now}"


    doc_sets = [[]]
    doc_set = doc_sets[-1]
    row_no = 0
    rows.each do |row|
      row_no +=1
      if row_no > @dataset_max_size
        doc_sets << []
        doc_set = doc_sets[-1]
        row_no = 0
      end
      doc_set << self.method(doc_creation_method_name).call(row)
    end

    puts "#### step #{step_no}.3 Delete all #{product_type} Products #{Time.now}"

    delete_index ('product_type')

    puts "#### step #{step_no}.4 Send all #{product_type} Products to solr index #{Time.now}"

    sent_to_index_in_batches(doc_sets)

    puts "step #{step_no} done #{Time.now}"
  end

  def run
    step_no = 1
    puts "#### Starting #{Time.now}"


    if @process_mice == true
      process_product_and_send_to_solr_core(step_no, 'mouse', self.class.mice_lines_sql, 'create_mouse_doc')
      step_no += 1
    end

    if @process_es_cells == true
      process_product_and_send_to_solr_core(step_no, 'es_cell', self.class.es_cell_sql, 'create_es_cell_doc')
      step_no += 1
    end

    if @process_targeting_vectors == true
      process_product_and_send_to_solr_core(step_no, 'targeting_vector', self.class.targeting_vectors_sql, 'create_targeting_vector_doc')
      step_no += 1
    end

    if @process_intermediate_vectors == true
      process_product_and_send_to_solr_core(step_no, 'intermediate_vector', self.class.intermediate_vectors_sql, 'create_intermediate_vector_doc')
      step_no += 1
    end
  end

  def allele_symbol row
    allele_symbol = 'None'
      allele_symbol = row['allele_symbol_superscript'] if ! row['allele_symbol_superscript'].to_s.empty?
    if !row['allele_symbol_superscript_template'].to_s.empty?
      allele_symbol = row['allele_symbol_superscript_template'].to_s.gsub(/\@/, row['mi_attempt_mouse_allele_type'].to_s) if ! row['mi_attempt_mouse_allele_type'].to_s.empty?
      allele_symbol = row['allele_symbol_superscript_template'].to_s.gsub(/\@/, row['phenotype_attempt_mouse_allele_type'].to_s) if ! row['phenotype_attempt_mouse_allele_type'].to_s.empty?
    end
    allele_symbol
  end

  def allele_type row
    allele_type = row['es_cell_allele_type']
    allele_type = row['mi_attempt_mouse_allele_type'] if ! row['mi_attempt_mouse_allele_type'].to_s.empty?
    allele_type = row['phenotype_attempt_mouse_allele_type'] if ! row['phenotype_attempt_mouse_allele_type'].to_s.empty?

    allele_type
  end


  def create_mouse_doc row
    doc = {"marker_symbol"              => row["marker_symbol"],
     "mgi_accession_id"                 => row["mgi_accession_id"],
     "allele_type"                      => allele_type(row),
     "allele_name"                      => allele_symbol(row),
     "type"                             => 'mouse',
     "name"                             => row["colony_name"],
     "genetic_info"                     => ["background_colony_strain:#{row['background_colony_strain_name']}", "deleter_strain:#{row['deleter_strain_name']}", "test_strain:#{row['test_strain_name']}"],
     "production_centre"                => row["production_centre"],
     "production_completed"             => ['Genotype confirmed','Cre Excision Complete'].includes?(row['mouse_status'] ? 'true' : 'false'),
     "status"                           => row["mouse_status"],
     "production_info"                  => ["type_of_microinjection:#{row["crispr_plan"] == true ? 'Casp9/Crispr' : 'ES Cell'}"],
     "associated_product_es_cell_name"  => row["es_cell_name"],
     "associated_product_vector_name"   => row["vector_name"],
     "order_names"                      => [],
     "order_links"                      => []
    }

    distribution_centres = self.class.get_distribution_centres(row)

    distribution_centres.each do |dis_centre|
      order_name, order_link = self.class.mice_order_links(dis_centre, row["ikmc_project_id"], row["marker_symbol"])
      if order_name && order_link
        doc["order_names"] << order_name
        doc["order_links"] << order_link
      end
    end
    other_links(doc, row)
    doc
  end

  def create_es_cell_doc row
    doc = {"marker_symbol"              => row['marker_symbol'],
     "mgi_accession_id"                 => row['mgi_accession_id'],
     "allele_type"                      => row['es_cell_allele_type'],
     "allele_name"                      => row["allele_symbol_superscript"],
     "genetic_info"                     => ["cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}","parent_es_cell_line:#{row['parental_cell_line']}"],
     "type"                             => 'es_cell',
     "name"                             => row['es_cell_name'],
     "production_pipeline"              => '',
     "production_completed"             => 'true',
     "status"                           => '',
     "associated_products_colony_names" => row['colonies'],
     "associated_products_vector_names" => row['vector_name']
    }

    self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))
    other_links(doc, row)
    doc
  end

  def create_targeting_vector_doc row
    doc = {"marker_symbol"               => row['marker_symbol'],
     "mgi_accession_id"                  => row['mgi_accession_id'],
     "allele_type"                       => '',
     "allele_name"                       => '',
     "genetic_info"                      => ["cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}", "backbone:#{row['backbone']}"],
     "type"                              => 'targeting_vector',
     "name"                              => row['vector_name'],
     "production_pipeline"               => '',
     "distribution_centre"               => '',
     "production_completed"              => 'true',
     "status"                            => '',
     "associated_products_es_cell_names" => row['es_cell_names']
    }

    allele_type, allele_name = self.class.process_vector_allele_type(self.class.convert_to_array(row['allele_names']), self.class.convert_to_array(row['allele_types']), row['allele_type'], row['pipeline'], row['cassette'])
    if allele_name && allele_type
      doc["allele_type"] = allele_type
      doc["allele_name"] = allele_name
    end

    self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))
    other_links(doc, row)
    doc
  end

  def create_intermediate_vector_doc row
    doc = {"marker_symbol"             => row['marker_symbol'],
     "mgi_accession_id"                => row['mgi_accession_id'],
     "allele_type"                     => '',
     "allele_name"                     => '',
     "type"                            => 'intermediate_vector',
     "production_pipeline"             => '',
     "distribution_centre"             => '',
     "production_completed"            => 'true',
     "status"                          => '',
     "associated_product_vector_name"  => row['vector_name']
    }
    other_links(doc, row)
    doc
  end



  def self.process_vector_allele_type (allele_names, allele_types, mutation_type_code, pipeline = '', cassette = '')
    if !allele_names.blank? and allele_types[0] != 'NULL' and allele_names[0] != 'NULL'
      return [allele_types[0], allele_names[0]]
    end

    cre_knock_in_suffix = /_(Cre[0-9A-Za-z]+)_/.match(cassette)

    allele_guess_hash = {'crd' => {'type' => 'a', 'allele_name' => "tm1a(#{pipeline})"},
     'tnc' => {'type' => 'e', 'allele_name' => "tm1e(#{pipeline})"},
     'del' => {'type' => '1', 'allele_name' => "tm1(#{pipeline})"},
     'cki' => {'type' => '1', 'allele_name' => "tm1(#{pipeline}#{cre_knock_in_suffix.blank? ? '' : cre_knock_in_suffix[1]})"}
      }

    return [] if mutation_type_code.blank? or !allele_guess_hash.has_key?(mutation_type_code)

    allele_name_guess = [allele_guess_hash[mutation_type_code]['type'], allele_guess_hash[mutation_type_code]['allele_name']]

    return allele_name_guess
  end

  def self.convert_to_array psql_array
    return [] if psql_array.blank?

    psql_array[1, psql_array.length-2].split(',')
  end

  def self.get_distribution_centres row
    return [] if row['distribution_centre_names'].blank?
    centres  = convert_to_array(row['distribution_centre_names'])
    networks = convert_to_array(row['distribution_networks'])
    starts   = convert_to_array(row['distribution_start_dates'])
    ends     = convert_to_array(row['distribution_end_dates'])

    distribution_centres = []
    count = centres.count
    return [] if count == 0
    (0...count).each do |i|
      distribution_centres << {:centre_name          => centres[i],
                               :distribution_network => networks[i],
                               :start_date           => starts[i] == 'NULL' ? nil : starts[i].to_time,
                               :end_date             => ends[i] == 'NULL' ? nil : ends[i].to_time
                               }
    end
    return distribution_centres
  end

  def self.processes_order_link(doc, order_link)
    doc['order_names'] = order_link[:names]
    doc['order_links'] = order_link[:urls]
  end


  def self.mice_order_links(distribution_centre, project_id, marker_symbol, config = nil)
    config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

    raise "Expecting to find KOMP in distribution centre config" if ! config.has_key? 'KOMP'
    raise "Expecting to find EMMA in distribution centre config" if ! config.has_key? 'EMMA'

    order_from_name ||= []
    order_from_url ||= []

    centre_name = distribution_centre[:centre_name]
    return [] if ! ['UCD', 'KOMP Repo', 'EMMA'].include?(centre_name) && !(config.has_key?(centre_name) || Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?(centre_name))
    current_time = Time.now

    if distribution_centre[:start_date]
      start_date = distribution_centre[:start_date]
    else
      start_date = current_time
    end

    if distribution_centre[:end_date]
      end_date = distribution_centre[:end_date]
    else
      end_date = current_time
    end

    range = start_date.to_time..end_date.to_time

    return [] if ! range.cover?(current_time)
    centre = Centre.where("contact_email IS NOT NULL AND name = '#{centre_name}'").first
    centre_name = 'KOMP' if ['UCD', 'KOMP Repo'].include?(centre_name)
    centre_name = distribution_centre[:distribution_network] if distribution_centre[:distribution_network]
    details = ''

    if config.has_key?(centre_name) && (!config[centre_name][:default].blank? || !config[centre_name][:preferred].blank?)
      # if blank then will default to order_from_url = details[:default]
      details = config[centre_name]
      order_from_url = details[:default]

      if !config[centre_name][:preferred].blank?
        project_id = project_id
        marker_symbol = marker_symbol
        order_from_name = centre_name

        # order of regex expression doesn't matter: http://stackoverflow.com/questions/5781362/ruby-operator

        if project_id &&  details[:preferred] =~ /PROJECT_ID/
          order_from_url = details[:preferred].gsub(/PROJECT_ID/, project_id)
        end

        if marker_symbol && details[:preferred] =~ /MARKER_SYMBOL/
          order_from_url = details[:preferred].gsub(/MARKER_SYMBOL/, marker_symbol)
        end
      end
    elsif centre
      details = centre
      order_from_url = "mailto:#{details.contact_email}?subject=Mutant mouse enquiry"
      order_from_name = centre_name
    end

    return [] if details.blank?

    if order_from_url
      return [order_from_name, order_from_url]
    else
      return []
    end
  end

  def other_links doc, row
    doc["other_links"] = []
  end

  def self.es_cell_and_targeting_vector_order_links(mgi_accession_id, marker_symbol, pipeline, ikmc_project_id)

    return {:urls => [], :names => []} if pipeline.blank?

    if ['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].include?(pipeline)
      return {:urls => ["http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells"], :names => ['EUMMCR']}

    elsif ['KOMP-CSD', 'KOMP-Regeneron'].include?(pipeline)
      if ! ikmc_project_id.blank?
        if ikmc_project_id.match(/^VG/)
          project = ikmc_project_id
        else
          project = 'CSD' + ikmc_project_id
        end
        url = "http://www.komp.org/geneinfo.php?project=#{project}"
      else
        url = "http://www.komp.org/"
      end

      return {:urls => [url], :names => ['KOMP']}

    elsif ['mirKO'].include?(pipeline)
      return {:urls => ["http://www.eummcr.org/order?add=#{mgi_accession_id}&material=es_cells",
                        "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=#{marker_symbol}"],
              :names => ['EUMMCR', 'MMRRC']}

    elsif ['Sanger MGP'].include?(pipeline)
      return {:urls => ["mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{marker_symbol}"], :names => ['Wtsi']}

    elsif 'NorCOMM' == pipeline
      return {:urls => ['http://www.phenogenomics.ca/services/cmmr/escell_services.html'], :names => ['NorCOMM']}

    else
      puts "PIPELINE : #{pipeline}"
      raise "Pipeline not recognized"
    end
  end

end