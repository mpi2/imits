class Open::Gene < ::Gene

  # BEGIN Helper functions for clean reporting


  def self.gene_production_summary(gene_ids = nil, return_value = nil, statuses = nil)

    sql = <<-EOF

      WITH status_summary AS (

      SELECT production_summary.mi_plan_id, production_summary.gene_id, production_summary.consortium_id, production_summary.production_centre_id, production_summary.status_name, count(production_summary.mi_plan_id) AS status_count
      FROM
      (
        (SELECT mi_plans.id AS mi_plan_id, mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id, CASE WHEN mi_attempt_statuses.name IS NOT NULL THEN mi_attempt_statuses.name ELSE mi_plan_statuses.name END AS status_name
         FROM mi_plans
           JOIN mi_plan_statuses ON mi_plans.status_id = mi_plan_statuses.id
           LEFT JOIN (mi_attempts JOIN mi_attempt_statuses ON mi_attempts.status_id = mi_attempt_statuses.id) ON mi_plans.id = mi_attempts.mi_plan_id AND mi_attempts.report_to_public = true
           WHERE mi_plans.report_to_public = true
         #{gene_ids.nil? ? "" : "AND mi_plans.gene_id IN (#{gene_ids.join(', ')})"}
        )

        UNION ALL

        (SELECT mi_plans.id AS mi_plan_id, mi_plans.gene_id, mi_plans.consortium_id, mi_plans.production_centre_id, phenotype_attempt_statuses.name AS status_name
         FROM mi_plans
           JOIN phenotype_attempts ON mi_plans.id = phenotype_attempts.mi_plan_id AND phenotype_attempts.report_to_public = true
           JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempts.status_id
           JOIN mi_attempts ON mi_attempts.id = phenotype_attempts.mi_attempt_id AND mi_attempts.report_to_public = true
         WHERE mi_attempts.is_active = true
           #{gene_ids.nil? ? "" : "AND mi_plans.gene_id IN (#{gene_ids.join(', ')})"}
        )
      ) AS production_summary
      #{statuses.nil? ? "" : "WHERE production_summary.status_name IN (#{statuses.map{|status| status.name}.join(',')})"}
      GROUP BY production_summary.mi_plan_id, production_summary.gene_id, production_summary.consortium_id, production_summary.production_centre_id, production_summary.status_name
      )

      SELECT genes.marker_symbol AS marker_symbol, consortia.name AS consortium, centres.name AS centre, status_summary.status_name AS status_name, status_summary.mi_plan_id AS mi_plan_id, status_summary.status_count AS status_count
      FROM status_summary
        JOIN genes ON genes.id = status_summary.gene_id
        JOIN consortia ON consortia.id = status_summary.consortium_id
        JOIN centres ON centres.id = status_summary.production_centre_id
      ORDER BY genes.marker_symbol, status_summary.status_name, consortia.name, centres.name
    EOF

    result = ActiveRecord::Base.connection.execute(sql)

    data = {}
    data['full_data'] = {}
    data['assigned plans'] = {}
    data['non assigned plans'] = {}
    data['in progress mi attempts'] = {}
    data['genotype confirmed mi attempts'] = {}
    data['aborted mi attempts'] = {}
    data['phenotype attempts'] = {}

    result.each do |production_record|

      data['full_data'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => production_record['status_count']}

      if ['Micro-injection in progress', 'Chimeras obtained'].include?(production_record['status_name'])
        if !data['in progress mi attempts'].has_key?(production_record['mi_plan_id'])
          data['in progress mi attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['in progress mi attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Genotype confirmed'].include?(production_record['status_name'])
        if !data['genotype confirmed mi attempts'].has_key?(production_record['mi_plan_id'])
          data['genotype confirmed mi attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['genotype confirmed mi attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Micro-injection aborted'].include?(production_record['status_name'])
        if !data['aborted mi attempts'].has_key?(production_record['mi_plan_id'])
          data['aborted mi attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['aborted mi attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted'].include?(production_record['status_name'])
        if !data['phenotype attempts'].has_key?(production_record['mi_plan_id'])
          data['phenotype attempts'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['phenotype attempts'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      elsif ['Assigned', 'Assigned - ES Cell QC In Progress', 'Assigned - ES Cell QC Complete'].include?(production_record['status_name'])
        if !data['assigned plans'].has_key?(production_record['mi_plan_id'])
          data['assigned plans'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['assigned plans'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i

      else
        if !data['non assigned plans'].has_key?(production_record['mi_plan_id'])
          data['non assigned plans'][production_record['mi_plan_id']] = {:marker_symbol => production_record['marker_symbol'], :mi_plan_id => production_record['mi_plan_id'], :consortium => production_record['consortium'], :centre => production_record['centre'], :status_name => production_record['status_name'], :status_count => 0}
        end
        data['non assigned plans'][production_record['mi_plan_id']][:status_count] += production_record['status_count'].to_i
      end
    end

    return return_value.nil? ? data : data[return_value]
  end


end


# == Schema Information
#
# Table name: genes
#
#  id                                 :integer          not null, primary key
#  marker_symbol                      :string(75)       not null
#  mgi_accession_id                   :string(40)
#  ikmc_projects_count                :integer
#  conditional_es_cells_count         :integer
#  non_conditional_es_cells_count     :integer
#  deletion_es_cells_count            :integer
#  other_targeted_mice_count          :integer
#  other_condtional_mice_count        :integer
#  mutation_published_as_lethal_count :integer
#  publications_for_gene_count        :integer
#  go_annotations_for_gene_count      :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  chr                                :string(2)
#  start_coordinates                  :integer
#  end_coordinates                    :integer
#  strand_name                        :string(255)
#  vega_ids                           :string(255)
#  ncbi_ids                           :string(255)
#  ensembl_ids                        :string(255)
#  ccds_ids                           :string(255)
#  marker_type                        :string(255)
#
# Indexes
#
#  index_genes_on_marker_symbol     (marker_symbol) UNIQUE
#  index_genes_on_mgi_accession_id  (mgi_accession_id) UNIQUE
#
