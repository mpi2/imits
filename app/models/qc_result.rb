class QcResult < ActiveRecord::Base
  def self.na
    @@na ||= self.find_by_description!('na')
  end

  def self.pass
    @@pass ||= self.find_by_description!('pass')
  end

  def self.fail
    @@fail ||= self.find_by_description!('fail')
  end
end

# == Schema Information
# Schema version: 20110921000001
#
# Table name: qc_results
#
#  id          :integer         not null, primary key
#  description :string(50)      not null
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_qc_results_on_description  (description) UNIQUE
#

