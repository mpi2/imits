# encoding: utf-8

class ReportCache < ActiveRecord::Base
  class Error < RuntimeError; end

  def compact_timestamp
    return updated_at.strftime('%Y%m%d%H%M%S')
  end

  def to_table
    raise Error, 'ReportCache must be in HTML format' unless format == 'csv'
    parsed_data = CSV.parse(data)
    return Ruport::Data::Table.new(
      :column_names => parsed_data[0],
      :data => parsed_data[1..-1]
    )
  end
end

# == Schema Information
#
# Table name: report_caches
#
#  id         :integer         not null, primary key
#  name       :text            not null
#  data       :text            not null
#  created_at :datetime
#  updated_at :datetime
#  format     :text            not null
#
# Indexes
#
#  index_report_caches_on_name  (name) UNIQUE
#

