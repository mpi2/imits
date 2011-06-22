class QcResult < ActiveRecord::Base
end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: qc_results
#
#  id          :integer         not null, primary key
#  description :text            not null
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_qc_results_on_description  (description) UNIQUE
#
