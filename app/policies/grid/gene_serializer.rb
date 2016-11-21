# encoding: utf-8

class Grid::GeneSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    marker_symbol
    mgi_accession_id
    ikmc_projects_count
    pretty_print_types_of_cells_available
    non_assigned_mi_plans
    assigned_mi_plans
    pretty_print_aborted_mi_attempts
    pretty_print_mi_attempts_in_progress
    pretty_print_mi_attempts_genotype_confirmed
    pretty_print_phenotype_attempts
  }

  def initialize(gene)
    @gene = gene
  end

  def as_json
    json_hash = super(@gene)
    return json_hash
  end
end
