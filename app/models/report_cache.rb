class ReportCache < ActiveRecord::Base
  def compact_timestamp
    return updated_at.strftime('%Y%m%d%H%M%S')
  end
end

# == Schema Information
#
# Table name: report_caches
#
#  id         :integer         not null, primary key
#  name       :text            not null
#  csv_data   :text            not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_report_caches_on_name  (name) UNIQUE
#

