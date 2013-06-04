class TargRep::CentrePipeline < ActiveRecord::Base
  serialize :centres, Array
end

# == Schema Information
#
# Table name: targ_rep_centre_pipelines
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  centres    :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

