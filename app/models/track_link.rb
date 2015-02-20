class TrackLink < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  def self.readable_name
    return 'track_links'
  end

end

# == Schema Information
#
# Table name: track_links
#
#  id           :integer          not null, primary key
#  ip_address   :string(255)
#  http_refer   :string(255)
#  link_clicked :string(255)
#  link_type    :string(255)
#  year         :integer
#  month        :integer
#  day          :integer
#  created_at   :datetime
#
