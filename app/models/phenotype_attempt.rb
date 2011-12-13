# encoding: utf-8

class PhenotypeAttempt < ActiveRecord::Base
  acts_as_audited

  include PhenotypeAttempt::StatusChanger

  belongs_to :mi_attempt
  belongs_to :status

  validate :mi_attempt do |myself|
    if myself.mi_attempt and myself.mi_attempt.mi_attempt_status != MiAttemptStatus.genotype_confirmed
      myself.errors.add(:mi_attempt, "status must be genotype confirmed (is currently '#{myself.mi_attempt.mi_attempt_status.description}')")
    end
  end

  before_validation :change_status

end

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                               :integer         not null, primary key
#  mi_attempt_id                    :integer         not null
#  status_id                        :integer         not null
#  is_active                        :boolean         default(TRUE), not null
#  rederivation_started             :boolean         default(FALSE), not null
#  rederivation_complete            :boolean         default(FALSE), not null
#  number_of_cre_matings_started    :integer         default(0), not null
#  number_of_cre_matings_successful :integer         default(0), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#

