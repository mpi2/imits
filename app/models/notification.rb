class Notification < ActiveRecord::Base
  include Notification::StatusChecker
  extend ::AccessAssociationByAttribute
  acts_as_audited

  attr_accessor :relevant_statuses, :retry
  attr_accessible :last_email_sent, :welcome_email_sent, :last_email_text, :welcome_email_text, :relevant_statuses

  belongs_to :contact
  belongs_to :gene

  validates :contact, :presence => true
  validates :gene, :presence => true

  access_association_by_attribute :contact, :email
  access_association_by_attribute :gene, :marker_symbol

  def welcome_email
    return if welcome_email_text.blank?
    YAML.load(welcome_email_text).raw_source
  end

  def last_email
    return if last_email_text.blank?
    YAML.load(last_email_text).raw_source
  end

  def retry!
    if last_email_sent.blank?
      self.welcome_email_sent = Time.now.utc
      self.retry = true
      self.save!
      NotificationMailer.welcome_email(self).deliver
    else
      self.last_email_sent = Time.now.utc
      self.retry = true
      self.save!
      NotificationMailer.status_email(self).deliver
    end
  end

end

# == Schema Information
#
# Table name: notifications
#
#  id                 :integer         not null, primary key
#  welcome_email_sent :datetime
#  welcome_email_text :text
#  last_email_sent    :datetime
#  last_email_text    :text
#  gene_id            :integer         not null
#  contact_id         :integer         not null
#  created_at         :datetime
#  updated_at         :datetime
#

