class ConsistentAlleleValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return if record.allele.blank? || record.targeting_vector.blank?

    begin

      my_allele       = record.allele
      targ_vec_allele = record.targeting_vector.allele

      valid = targ_vec_allele.id == my_allele.id or (
        my_allele.mgi_accession_id    == targ_vec_allele.mgi_accession_id   and
        my_allele.project_design_id   == targ_vec_allele.project_design_id  and
        my_allele.mutation_type       == targ_vec_allele.mutation_type      and
        my_allele.cassette            == targ_vec_allele.cassette           and
        my_allele.backbone            == targ_vec_allele.backbone           and
        my_allele.homology_arm_start  == targ_vec_allele.homology_arm_start and
        my_allele.homology_arm_end    == targ_vec_allele.homology_arm_end   and
        my_allele.cassette_start      == targ_vec_allele.cassette_start     and
        my_allele.cassette_end        == targ_vec_allele.cassette_end
      )

    rescue => e
      valid = false
    end

    record.errors[attribute] << (options[:message] || "is invalid. This ES Cell has a different allele (alleleXXX) compared to its targeting vector (alleleYYY). However the allele can only mismatch in the presence / absence of the loxP site!") unless valid
  end

end