# encoding: utf-8

class Rest::GeneSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    marker_symbol
    mgi_accession_id
    chr
    start_coordinates
    end_coordinates
    strand_name
    vega_ids
    ncbi_ids
    ensembl_ids
    ccds_ids
    marker_type
    feature_type
    synonyms
    komp_repo_geneid
    marker_name
    cm_position
  }

  def initialize(gene, options = {})
    @options = options
    @gene = gene
  end

  def as_json
    json_hash = super(@gene, @options)
    return json_hash
  end
end
