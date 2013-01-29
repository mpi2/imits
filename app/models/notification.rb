class Notification < ActiveRecord::Base
  include Notification::StatusChecker
  extend ::AccessAssociationByAttribute
  acts_as_audited

  attr_accessor :relevant_statuses, :retry
  attr_accessible :last_email_sent, :welcome_email_sent, :last_email_text, :welcome_email_text, :relevant_statuses, :gene_marker_symbol, :gene_mgi_accession_id, :contact_email

  belongs_to :contact
  belongs_to :gene
  
  access_association_by_attribute :contact, :email, :validates => false
  access_association_by_attribute :gene, :marker_symbol
  access_association_by_attribute :gene, :mgi_accession_id

  validates :gene, :presence => true

  ## Check if contact_email has been provided. Create new contact if one doesn't exist.
  validate do
    if self.contact_email.blank?
      self.errors.add :contact_email, "is blank"
      return
    end

    if self.contact_email && self.contact.blank?
      self.contact = Contact.create(:email => self.contact_email)
    end
  end

  validates :contact_id, :presence => true, :uniqueness => {:scope => :gene_id, :message => "Already registered for this contact and gene"}

  before_create :send_welcome_email

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

  private

    def send_welcome_email
      return unless valid?
      
      if mailer = NotificationMailer.welcome_email(self)
        self.welcome_email_text = mailer.body
        self.welcome_email_sent = Time.now.utc
        
        mailer.deliver
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

