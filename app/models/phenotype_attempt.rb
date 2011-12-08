class PhenotypeAttempt < ActiveRecord::Base
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

