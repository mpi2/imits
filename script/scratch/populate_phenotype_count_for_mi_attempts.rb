#!/usr/bin/env ruby

ApplicationModel.audited_transaction do
  mi_attempts_rec = MiAttempt.all
  mi_attempts_rec.each do |rec|
    count = PhenotypeAttempt.search(:status_name_not_eq => 'Phenotype Attempt Aborted', :mi_attempt_id_eq => rec.id).result.all.count
    #a = MiAttempt.find_by_id(rec.id)
    rec.update_attributes!(:phenotype_count => count, :audit_comment => "populate_phenotype_count_for_mi_attempt")
  end
  #raise 'Rollback'
end
