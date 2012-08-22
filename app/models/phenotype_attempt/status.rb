# encoding: utf-8

class PhenotypeAttempt::Status < ActiveRecord::Base
  def self.[](name)
    return self.find_by_name!(name)
  end

  def self.post_cre_excision_complete
    return [
      PhenotypeAttempt::Status['Cre Excision Complete'],
      PhenotypeAttempt::Status['Phenotyping Started'],
      PhenotypeAttempt::Status['Phenotyping Complete']
    ]
  end

end

# == Schema Information
#
# Table name: phenotype_attempt_statuses
#
#  id         :integer         not null, primary key
#  name       :string(50)      not null
#  created_at :datetime
#  updated_at :datetime
#  order_by   :integer
#  code       :string(10)      not null
#

