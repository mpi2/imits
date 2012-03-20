# encoding: utf-8

class PhenotypeAttempt::StatusStamp < ActiveRecord::Base
  acts_as_audited

  belongs_to :phenotype_attempt
  belongs_to :status
end

# == Schema Information
#
# Table name: phenotype_attempt_status_stamps
#
#  id                   :integer         not null, primary key
#  phenotype_attempt_id :integer         not null
#  status_id            :integer         not null
#  created_at           :datetime
#  updated_at           :datetime
#

