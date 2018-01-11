class EmailTemplate < ActiveRecord::Base

  acts_as_audited

  validates :status, :uniqueness => true, :unless => :blank?
  validates :welcome_body, :presence => true
  validates :update_body, :presence => true

  def self.readable_name
    return 'email_template'
  end

end

# == Schema Information
#
# Table name: email_templates
#
#  id           :integer          not null, primary key
#  status       :string(255)
#  welcome_body :text
#  update_body  :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
