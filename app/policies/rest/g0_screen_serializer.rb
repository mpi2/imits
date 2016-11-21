# encoding: utf-8

class Rest::G0ScreenSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    marker_symbol
    no_g0_where_mutation_detected
    no_nhej_g0_mutants
    no_deletion_g0_mutants
    no_hr_g0_mutants
    no_hdr_g0_mutants
    no_hdr_g0_mutants_all_donors_inserted
    no_hdr_g0_mutants_subset_donors_inserted
  }


  def initialize(mutagenesis_factor)
    @mutagenesis_factor = mutagenesis_factor
  end

  def as_json
    json_hash = super(@mutagenesis_factor)

    return json_hash
  end

end
