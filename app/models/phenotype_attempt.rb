class PhenotypeAttempt < ActiveRecord::Base
  belongs_to :mi_attempt

  validate :mi_attempt do |myself|
    if myself.mi_attempt.mi_attempt_status != MiAttemptStatus.genotype_confirmed
      myself.errors.add(:mi_attempt, "status must be genotype confirmed (is currently '#{myself.mi_attempt.mi_attempt_status.description}')")
    end
  end
end

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id            :integer         not null, primary key
#  mi_attempt_id :integer         not null
#  is_active     :boolean         default(TRUE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

