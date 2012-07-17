#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  mi_attempts_rec = MiAttempt.all
  mi_attempt_rec.each |rec| do
    count = PhenotypeAttempt.search(:status_name_not_eq => 'Phenotype Attempt Aborted', :id_eq => rec.id.).result.all.count
    MiAttempt.find_by_id(rec.id).update_attributes!(:phenotype_count => count)
  end
  raise ActiveRecord::Rollback
end