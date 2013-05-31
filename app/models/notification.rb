
require 'pp'

class Notification < ActiveRecord::Base
  include Notification::StatusChecker
  extend ::AccessAssociationByAttribute
  acts_as_audited

  attr_accessor :relevant_statuses, :retry
  attr_accessible :last_email_sent, :welcome_email_sent, :last_email_text, :welcome_email_text, :relevant_statuses, :gene_marker_symbol, :gene_mgi_accession_id, :contact_email

  belongs_to :contact
  belongs_to :gene

  access_association_by_attribute :contact, :email, :skip_validation => true
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

  #before_create :send_welcome_email

  #def welcome_email
  #  return if welcome_email_text.blank?
  #  welcome_email_text
  #end

  def last_email
    return if last_email_text.blank?
    last_email_text
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

  def self.notifications_by_gene
    sql = <<-EOF
    SELECT genes.marker_symbol, count(*) as total
    FROM notifications
    JOIN contacts ON contacts.id = notifications.contact_id
    JOIN genes ON genes.id = notifications.gene_id
    WHERE contacts.report_to_public is true
    GROUP BY genes.marker_symbol
    ORDER BY total desc, genes.marker_symbol;
    EOF

    result = ActiveRecord::Base.connection.execute sql
    result.to_a.map(&:symbolize_keys)
  end

  private

  #def send_welcome_email
  #  return unless valid?
  #
  #  if mailer = NotificationMailer.welcome_email(self)
  #    self.welcome_email_text = mailer.body.to_s
  #    self.welcome_email_sent = Time.now.utc
  #
  #    mailer.deliver
  #  end
  #end

  #def self.send_welcome_email_bulk_1
  #  #self.find_all_by_contact_id
  #
  #
  #
  #  # for each contact
  #  # gather all notifications
  #  # create @symbol hash for each
  #  # whack it to template
  #
  #  #contacts = Contact.all
  #  #pp contacts
  #  #
  #  #notifications = self.all
  #  #pp notifications
  #
  #  #notifications = self.group("contact_id")
  #  #pp notifications
  #
  #  #Category.joins(:posts)
  #
  #  #contacts = Contact.joins(:notifications)
  #  contacts = Contact.joins(:notifications).where('notifications.welcome_email_sent is null')
  #  #puts "#### contacts:"
  #  #pp contacts
  #
  #  #@states = People.where(first_name: 'Bob').uniq.pluck(:state)
  #
  #  contactsz = Contact.joins(:notifications).where('notifications.welcome_email_sent is null').uniq.pluck(:id)
  #  #puts "#### contactsz:"
  #  #pp contactsz
  #
  #
  #  array = []
  #
  #  contactsz.each do |contactsz|
  #    notifications = self.where("contact_id = #{contactsz}")
  #    puts "\n#### notifications: (#{notifications.size})"
  #    pp notifications
  #
  #    contact = Contact.find contactsz
  #
  #    notifications.each do |notification|
  #      gene = Gene.find notification.gene_id
  #
  #      modifier_string = "is not"
  #      gene.mi_plans.each do |plan|
  #        if plan.is_active?
  #          modifier_string = "is"
  #          break
  #        end
  #      end
  #
  #      hash = {
  #        :marker_symbol=> gene.marker_symbol,
  #        :modifier_string => "is not",
  #        :relevant_status => gene.relevant_status,
  #        :total_cell_count => gene.es_cells_count,
  #        :conditional_es_cells_count => gene.conditional_es_cells_count,
  #        :non_conditional_es_cells_count => gene.non_conditional_es_cells_count,
  #        :deletion_es_cells_count => gene.deletion_es_cells_count,
  #        :mgi_accession_id => gene.mgi_accession_id,
  #        :contact_email => contact.email
  #      }
  #      array.push(hash)
  #    end
  #
  #    puts "\n#### array:"
  #    pp array
  #  end
  #
  #
  #
  #  #
  #  #notifications.each do |notification|
  #  #  #notifications =
  #  #end
  #
  #end

  #def self.send_welcome_email_bulk
  #  contacts = Contact.joins(:notifications).where('notifications.welcome_email_sent is null').uniq.pluck(:id)
  #
  #  contact_array = []
  #
  #  contacts.each do |contact_id|
  #    genes_array = []
  #    notifications = self.where("contact_id = #{contact_id}")
  #    #puts "\n#### notifications: (#{notifications.size})"
  #    #pp notifications
  #
  #    contact = Contact.find contact_id
  #
  #    notifications.each do |notification|
  #      gene = Gene.find notification.gene_id
  #
  #      modifier_string = "is not"
  #
  #      gene.mi_plans.each do |plan|
  #        if plan.is_active?
  #          modifier_string = "is"
  #          break
  #        end
  #      end
  #
  #      relevant_status = gene.relevant_status
  #      relevant_status = relevant_status ? { :status => relevant_status[:status], :date => relevant_status[:date] }: nil
  #
  #      hash = {
  #        :marker_symbol => gene.marker_symbol,
  #        :modifier_string => "is not",
  #        :relevant_status => relevant_status,
  #        :total_cell_count => gene.es_cells_count,
  #        :conditional_es_cells_count => gene.conditional_es_cells_count,
  #        :non_conditional_es_cells_count => gene.non_conditional_es_cells_count,
  #        :deletion_es_cells_count => gene.deletion_es_cells_count,
  #        :mgi_accession_id => gene.mgi_accession_id,
  #        :notification_id => notification.id
  #      }
  #      genes_array.push(hash)
  #    end
  #
  #    #puts "\n#### array:"
  #    #pp array
  #
  #    contact_array.push({:contact_email => contact.email, :genes => genes_array})
  #
  #    #NotificationMailer.welcome_email_new({:contact_email => contact.email, :genes => genes_array})
  #  end
  #
  #  #puts "\n#### contact_array:"
  #  #pp contact_array
  #
  #  #if mailer = NotificationMailer.welcome_email(self)
  #  #  self.welcome_email_text = mailer.body.to_s
  #  #  self.welcome_email_sent = Time.now.utc
  #  #
  #  #  mailer.deliver
  #  #end
  #
  #  contact_array.each do |contact|
  #    #puts "#### contact:"
  #    #pp contact
  #    mailer = NotificationMailer.welcome_email_new(contact)
  #    next if ! mailer
  #
  #    self.transaction do
  #
  #      contact[:genes].each do |gene|
  #        notification = self.find gene[:notification_id]
  #        notification.welcome_email_text = mailer.body.to_s
  #        notification.welcome_email_sent = Time.now.utc
  #        notification.save!
  #      end
  #
  #      mailer.deliver
  #    end
  #  end
  #
  #end
  #
  #def self.send_status_emails
  #  excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']
  #
  #  ApplicationModel.audited_transaction do
  #    Notification.all.each do |notification|
  #      next if notification.gene.relevant_status.empty?
  #      next if excluded_statuses.any? {|status| notification.gene.relevant_status[:status].include? status}
  #      next if notification.check_statuses.empty?
  #
  #      mailer = NotificationMailer.status_email(notification)
  #      notification.last_email_text = mailer.body.to_s
  #      notification.last_email_sent = Time.now.utc
  #      notification.save!
  #      mailer.deliver
  #    end
  #  end
  #end
  #
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
