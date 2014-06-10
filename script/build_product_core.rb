#!/usr/bin/env ruby

require 'pp'
require "digest/md5"


module SolrConnect

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
      <<-EOF
        WITH es_cell_names AS (
          SELECT targ_rep_es_cells.targeting_vector_id AS targeting_vector_id, array_agg(targ_rep_es_cells.name) AS list
          FROM targ_rep_es_cells
          GROUP BY targ_rep_es_cells.targeting_vector_id
        )

        SELECT genes.marker_symbol AS marker_symbol,
               genes.mgi_accession_id AS mgi_accession_id,
               targ_rep_alleles.cassette AS cassette,
               targ_rep_alleles.cassette_type AS cassette_type,
               targ_rep_alleles.backbone AS backbone,
               targ_rep_targeting_vectors.name AS vector_name,
               'Targeting Vector' AS vector_type,
               es_cell_names.list AS es_cell_names,
               targ_rep_pipelines.name AS pipeline,
               targ_rep_ikmc_projects.name AS ikmc_project_id
        FROM targ_rep_targeting_vectors
          JOIN targ_rep_alleles ON targ_rep_targeting_vectors.allele_id = targ_rep_alleles.id
          JOIN genes ON genes.id = targ_rep_alleles.gene_id
          LEFT JOIN es_cell_names ON es_cell_names.targeting_vector_id = targ_rep_targeting_vectors.id
          LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
          LEFT JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
        WHERE targ_rep_targeting_vectors.report_to_public = true
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
          JOIN es_cells ON mi_attempts.es_cell_id = es_cells.id)
          LEFT JOIN strains AS cb_strain ON cb_strain.id = mouse_allele_mods.colony_background_strain_id
          LEFT JOIN deleter_strains AS del_strain ON del_strain.id = mouse_allele_mods.colony_background_strain_id
          LEFT JOIN distribution_centres On distribution_centres.phenotype_attempt_id = mouse_allele_mods.phenotype_attempt_id
        WHERE mouse_allele_mods.report_to_public = true AND mouse_allele_mods.cre_excision = true
      EOF
    end



    def initialize
    end

    def send_to_index data
#      pp data
#      proxy = SolrConnect::Proxy.new(@solr_url)
#      proxy.update(data.join, @solr_user, @solr_password)
#      proxy.update({'commit' => {}}.to_json, @solr_user, @solr_password)
    end


    def run

      puts "#### step 1 select mouse line products"
      rows = ActiveRecord::Base.connection.execute(self.class.mice_lines_sql)

      rows.each do |row|
        create_mouse_doc(row)
        send_to_index(mouse_doc)
      end

      puts "#### step 2 select ES Cell products"
      rows = ActiveRecord::Base.connection.execute(self.class.es_cell_sql)
      rows.each do |row|
        create_es_cell_doc(row)
        send_to_index(mouse_doc)
      end

      puts "#### step 3 select Targeting Vector products"
      rows = ActiveRecord::Base.connection.execute(self.class.targeting_vectors_sql)
      rows.each do |row|
        create_targeting_vector_doc(row)
        send_to_index(mouse_doc)
      end

      puts "#### step 4 select Intermediate Vector products"
      rows = ActiveRecord::Base.connection.execute(self.class.intermediate_vectors_sql)
      rows.each do |row|
        create_intermediate_doc(row)
        send_to_index(mouse_doc)
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
      doc = {"marker_symbol"    => row["marker_symbol"],
       "mgi_accession_id"       => row["mgi_accession_id"],
       "allele_type"            => allele_type(row),
       "allele_name"            => allele_symbol(row),
       "genetic_background"     => ["background_colony_strain:#{row['background_colony_strain_name']}", "deleter_strain:#{row['deleter_strain_name']}", "test_strain:#{row['test_strain_name']}"],
       "type"                   => 'Mouse',
       "name"                   => row["colony_name"],
       "type_of_microinjection" => row["crispr_plan"] == true ? 'Casp9/Crispr' : 'ES Cell',
       "status"                 => row["mouse_status"],
       "production_centre"      => row["production_centre"],
       "es_cell_name"           => row["es_cell_name"],
       "vector_name"            => row["vector_name"]
      }

      distribution_centres = get_distribution_centres(row)

      self.class.processes_order_link(doc, self.class.mice_order_links(distribution_centres))
      other_links(doc, row)
      doc
    end

    def create_es_cell_doc row
      doc = {"marker_symbol"    => row['marker_symbol'],
       "mgi_accession_id"       => row['mgi_accession_id'],
       "allele_type"            => row['es_cell_allele_type'],
       "allele_name"            => row["allele_symbol_superscript"],
       "genetic_background"     => ["cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}"],
       "type"                   => 'ES Cell',
       "name"                   => row['es_cell_name'],
       "colony_names"           => row['colonies'],
       "parent_es_cell_line"    => row['parental_cell_line'],
       "vector_name"            => row['vector_name']
      }

      self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))
      other_links(doc, row)
      doc
    end

    def create_targeting_vector_doc row
      doc = {"marker_symbol"    => row['marker_symbol'],
       "mgi_accession_id"       => row['mgi_accession_id'],
       "allele_type"            => '',
       "allele_name"            => '',
       "genetic_background"     => ["cassette:#{row['cassette']}","cassette_type:#{row['cassette_type']}", "backbone:#{row['backbone']}"],
       "type"                   => 'Targeting Vector',
       "name"                   => row['vector_name'],
       "es_cell_names"          => row['es_cell_names']
      }

      self.class.processes_order_link(doc, self.class.es_cell_and_targeting_vector_order_links(row['mgi_accession_id'], row['marker_symbol'], row['pipeline'], row['ikmc_project_id']))
      other_links(doc, row)

      other_links(doc, row)
      doc
    end

    def create_intermediate_doc row
      doc = {"marker_symbol"    => row['marker_symbol'],
       "mgi_accession_id"       => row['mgi_accession_id'],
       "allele_type"            => '',
       "allele_name"            => '',
       "type"                   => 'Intermediate Vector',
       "vector_name"            => row['vector_name']
      }
      other_links(doc, row)
      doc
    end


    def get_distribution_centres row
      distribution_centres = []
      count = row['distribution_centre_names'].count
      (0...count).each do |i|
        distribution_centres << {:centre_name          => row['distribution_centre_names'][i]},
                                 :distribution_network => row['distribution_networks'][i],
                                 :start_date           => row['distribution_start_dates'][i],
                                 :end_date             => row['distribution_end_dates'][i]
                                 }
      end
      return distribution_centres
    end

    def self.processes_order_link(doc, order_link)
      doc['order_names'] = order_link[:names]
      doc['order_links'] = order_link[:urls]
    end


    def self.mice_order_links(object, distribution_centres, config = nil)
      config ||= YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

      raise "Expecting to find KOMP in distribution centre config" if ! config.has_key? 'KOMP'
      raise "Expecting to find EMMA in distribution centre config" if ! config.has_key? 'EMMA'

      order_from_names ||= []
      order_from_urls ||= []

      object.distribution_centres.each do |distribution_centre|
        centre_name = distribution_centre.centre.name

        next if ! ['UCD', 'KOMP Repo', 'EMMA'].include?(centre_name) && !(config.has_key?(centre_name) || Centre.where("contact_email IS NOT NULL").map{|c| c.name}.include?(centre_name))

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
        centre = Centre.where("contact_email IS NOT NULL AND name = '#{centre_name}'").first
        centre_name = 'KOMP' if ['UCD', 'KOMP Repo'].include?(centre_name)
        centre_name = distribution_centre.distribution_network if distribution_centre.distribution_network
        details = ''

        if config.has_key?(centre_name) && (!config[centre_name][:default].blank? || !config[centre_name][:preferred].blank?)
          # if blank then will default to order_from_url = details[:default]
          details = config[centre_name]
          order_from_url = details[:default]

          if !config[centre_name][:preferred].blank?
            project_id = object.es_cell.ikmc_project_id
            marker_symbol = object.gene.marker_symbol
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

        next if details.blank?

        if order_from_url
          solr_doc['order_from_names'].push order_from_name
          solr_doc['order_from_urls'].push order_from_url
        end
      end
    end




    def other_links doc, row
      doc["other_links"] = []
    end

    def self.es_cell_and_targeting_vector_order_links(mgi_accession_id, marker_symbol, pipeline, ikmc_project_id)

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
        raise "Pipeline not recognized"
      end
    end

  end
end