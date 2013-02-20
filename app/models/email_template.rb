class EmailTemplate < ActiveRecord::Base

  acts_as_audited

  validates :status, :uniqueness => true, :unless => :blank?
  validates :welcome_body, :presence => true
  validates :update_body, :presence => true

  def render(type = 'welcome')
    begin
      case type
        when 'welcome'
          puts welcome_body
          ERB.new(welcome_body).result
        when 'update'
          puts update_body
          ERB.new(update_body).result
      end
    rescue => e
      Rails.logger.info e.inspect
      Rails.logger.info "Could not load ERB template."
    end
  end

  def self.readable_name
    return 'email_template'
  end

end

# == Schema Information
#
# Table name: email_templates
#
#  id           :integer         not null, primary key
#  status       :string(255)
#  welcome_body :text
#  update_body  :text
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#

