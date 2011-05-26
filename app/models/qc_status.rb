class QcStatus < ActiveRecord::Base
end

# == Schema Information
# Schema version: 20110421150000
#
# Table name: qc_statuses
#
#  id          :integer         not null, primary key
#  description :text            not null
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_qc_statuses_on_description  (description) UNIQUE
#

