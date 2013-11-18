module TargRep::IkmcProject::IkmcProjectGenerator

  class Generate

    class << self

      def update_ikmc_projects
        find_and_create_new_projects_from_tarmits_products
        assign_project_id_to_tarmit_products
        update_status_of_projects_based_on_tarmits_products
        update_project_status_from_htgt_download
      end

      def find_and_create_new_projects_from_tarmits_products
        # create any new ikmc_projects belonging to recently added products (targeting vectors and clones)
        sql = <<-EOF
        SELECT t.ikmc_project_id AS ikmc_project_id, t.pipeline_id AS pipeline_id, Now(), NOW() FROM
        (SELECT DISTINCT ikmc_project_id, pipeline_id FROM targ_rep_es_cells WHERE ikmc_project_id IS NOT NULL AND ikmc_project_id !=''
        UNION
        SELECT DISTINCT ikmc_project_id, pipeline_id FROM targ_rep_targeting_vectors WHERE ikmc_project_id IS NOT NULL AND ikmc_project_id !='') AS t
        LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.name = t.ikmc_project_id AND targ_rep_ikmc_projects.pipeline_id= t.pipeline_id
        WHERE targ_rep_ikmc_projects.id IS NULL;
        EOF
        records = ActiveRecord::Base.connection.execute(sql)

        records.each do |project|
          ikmc_project = TargRep::IkmcProject.new(:name => project['ikmc_project_id'], :pipeline_id => project['pipeline_id'])
          if ikmc_project.valid?
            ikmc_project.save
          else
            console.log("Invalid project: name => #{project['ikmc_project_id']}, pipeline_id => #{project['pipeline_id']} ")
          end
        end
      end


      def assign_project_id_to_tarmit_products
        # update ikmc_project foreign key on;

        sql = <<-EOF
        SELECT DISTINCT targ_rep_ikmc_projects.id AS project_id, targ_rep_ikmc_projects.name AS project_name, targ_rep_ikmc_projects.pipeline_id AS pipeline_id, targ_rep_ikmc_projects.status_id AS status_id
        FROM targ_rep_ikmc_projects
        LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.ikmc_project_id = targ_rep_ikmc_projects.name AND targ_rep_es_cells.pipeline_id = targ_rep_ikmc_projects.pipeline_id
        LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.ikmc_project_id = targ_rep_ikmc_projects.name AND targ_rep_targeting_vectors.pipeline_id = targ_rep_ikmc_projects.pipeline_id
        WHERE (targ_rep_es_cells.ikmc_project_foreign_id IS NULL AND targ_rep_es_cells.id IS NOT NULL) OR (targ_rep_targeting_vectors.ikmc_project_foreign_id IS NULL AND targ_rep_targeting_vectors.id IS NOT NULL)
        ;
        EOF
        records = ActiveRecord::Base.connection.execute(sql)

        records.each do |ikmc_project|
          TargRep::EsCell.where("ikmc_project_id = '#{ikmc_project['project_name']}' AND pipeline_id = #{ikmc_project['pipeline_id']} AND (ikmc_project_foreign_id IS NULL OR ikmc_project_foreign_id != #{ikmc_project['project_id']})").each do |es_cell|
            es_cell.update_attributes(:ikmc_project_foreign_id => ikmc_project['project_id'])
          end
          TargRep::TargetingVector.where("ikmc_project_id = '#{ikmc_project['project_name']}' AND pipeline_id = #{ikmc_project['pipeline_id']} AND (ikmc_project_foreign_id IS NULL OR ikmc_project_foreign_id != #{ikmc_project['project_id']})").each do |target_vector|
            target_vector.update_attributes(:ikmc_project_foreign_id => ikmc_project['project_id'])
          end
        end
      end


      def update_status_of_projects_based_on_tarmits_products
        # update status of ikmc_projects for projects with products in tarmits
        sql = <<-EOF
        SELECT targ_rep_ikmc_projects.id AS ikmc_project_id, best_status.best_ikmc_project_status AS best_ikmc_project_status
        FROM
          (SELECT
            ikmc_project_statuses.ikmc_project_id AS ikmc_project_id,
            CASE MIN(ikmc_project_statuses.ikmc_project_status_order)
              WHEN 1 THEN 17                                      -- Mice - Phenotype Data Available
              WHEN 2 THEN 16                                      -- Mice - Genotype confirmed
              WHEN 3 THEN 15                                      -- Mice - Microinjection in progress
              WHEN 4 THEN 12                                       -- ES Cells - Targeting Confirmed
              WHEN 5 THEN 10                                       -- Vector Complete
              ELSE NULL
            END AS best_ikmc_project_status
            FROM
              (SELECT targ_rep_ikmc_projects.id AS ikmc_project_id,
              CASE WHEN phenotype_attempt_statuses.name = 'Phenotyping Started' THEN 1
                WHEN mi_attempt_statuses.name = 'Genotype confirmed' THEN 2
                WHEN mi_attempt_statuses.name IS NOT NULL THEN 3
                WHEN targ_rep_es_cells.id IS NOT NULL AND targ_rep_es_cells.report_to_public = 't' THEN 4
                WHEN targ_rep_targeting_vectors.id IS NOT NULL AND targ_rep_targeting_vectors.report_to_public = 't' AND  targ_rep_ikmc_project_statuses.name NOT IN ('#{es_cell_production_statuses_in_htgt.join("','")}') THEN 5
                ELSE 6
              END AS ikmc_project_status_order
              FROM
              targ_rep_ikmc_projects
              LEFT JOIN targ_rep_ikmc_project_statuses ON targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id
              LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
              LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
              LEFT JOIN (mi_attempts JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id AND mi_attempt_statuses.name != 'Micro-injection aborted' ) ON mi_attempts.es_cell_id = targ_rep_es_cells.id
              LEFT JOIN (phenotype_attempts JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempts.status_id AND phenotype_attempt_statuses.name != 'Phenotype Attempt Aborted' ) ON phenotype_attempts.mi_attempt_id = mi_attempts.id
              ) AS ikmc_project_statuses
          GROUP BY ikmc_project_statuses.ikmc_project_id
        ) AS best_status
        JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = best_status.ikmc_project_id
        WHERE targ_rep_ikmc_projects.status_id != best_status.best_ikmc_project_status
        EOF
        records = ActiveRecord::Base.connection.execute(sql)

        records.each do |ikmc_status|
          TargRep::IkmcProject.find(ikmc_status['ikmc_project_id']).update_attributes(:status_id => ikmc_status['best_ikmc_project_status'])
        end
      end

      def update_project_status_from_htgt_download
        require 'open-uri'
        # read file and update non mice, 'Vector Complete' and 'ES Cells - Targeting Confirmed' statuses. ie. statuses that cannot be worked out from the data stored in TarMits.

        headers = []
        data = {}
        statuses= {}

        url = "http://www.sanger.ac.uk/htgt/report/get_projects?view=csvdl&file=tmp.csv"
        open(url) do |file|
          headers = file.readline.strip.split(',')
          file.each_line do |line|
            row = line.strip.gsub(/\"/, '').split(',')
            project_index = headers.index('allele_id')
            status_index = headers.index('pipeline_status')
            eucomm_tools_index = headers.index('eucomm_tools')
            if row[eucomm_tools_index] == '1'
              data[row[project_index]] = {'ikmc_project_name' => row[project_index], 'status_name' => row[status_index], 'pipeline_id' => '7' }
            end
          end
        end

        sql = <<-EOF
        SELECT targ_rep_ikmc_projects.id AS ikmc_project_id, targ_rep_ikmc_projects.name AS ikmc_project_name, targ_rep_ikmc_project_statuses.name AS status_name, targ_rep_ikmc_project_statuses.product_type AS product_type
        FROM targ_rep_ikmc_projects
        LEFT JOIN targ_rep_ikmc_project_statuses ON targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id
        WHERE targ_rep_ikmc_projects.pipeline_id = 7 AND targ_rep_ikmc_projects.name IN ('#{data.keys.join("','")}')
        EOF

        results = ActiveRecord::Base.connection.execute(sql)

        sql = <<-EOF
        SELECT *
        FROM targ_rep_ikmc_project_statuses
        EOF

        all_statuses = ActiveRecord::Base.connection.execute(sql)

        all_statuses.each do |status|
          statuses[status["name"]] = status["id"]
        end

        results.each do |record|
          if ! (['ES Cells - Targeting Confirmed'].include?(record['status_name']) or record['product_type'] == 'Mice')
            if ( record['status_name'] != 'Vector Complete' and record['status_name'] != data[record['ikmc_project_name']]['status_name'] ) or
                 ( record['status_name'] == 'Vector Complete' and es_cell_production_statuses_in_htgt.include?(data[record['ikmc_project_name']]['status_name']) )
              TargRep::IkmcProject.find(record['ikmc_project_id']).update_attributes(:status_id => statuses[data[record['ikmc_project_name']]['status_name']])
            end
          end
          data.delete(record['ikmc_project_name'])
        end

        data.each do |key, record|
          project_value = record['ikmc_project_name']
          status_name_value = record['status_name']
          if status_name_value
            if !statuses.has_Key?(status_name_value)
              create_status = TargRep::IkmcProject:Status.new(:name => project_value, :status_id => status_value, :pipeline_id => 7)
              if create_status.valid?
                create_status.save
              else
                console.log("Invalid status: name => #{record['ikmc_project_name']}, pipeline_id => 7")
              end
            end
            status_value = statuses[status_name_value]
            if !project_value.blank? & !status_value.blank?
              create_project = TargRep::IkmcProject.new(:name => project_value, :status_id => status_value, :pipeline_id => 7)
              if create_project.valid?
                create_project.save
                data.delete(project_value)
              else
                console.log("Invalid project: name => #{record['ikmc_project_name']}, pipeline_id => 7")
              end
            end
          end
        end
      end

      def es_cell_production_statuses_in_htgt
        return [ 'ES Cells - Electroporation Unsuccessful',
                 'ES Cells - Electroporation in Progress',
                 'ES Cells - No QC Positives'
               ]
      end

    end
  end
end

