
class NotificationMailer < ActionMailer::Base

  include ActionView::Helpers::TextHelper

  default :from => 'info@mousephenotype.org'

  def welcome_email(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    @relevant_status = @gene.relevant_status

    set_attributes

    @email_template = EmailTemplate.find_by_status(@relevant_status[:status])
    email_body = ERB.new(@email_template.welcome_body).result(binding) rescue nil

    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text { render :inline => email_body }
    end
  end

  def welcome_email_bulk(contact)
    @genes = contact[:genes]
    @contact_email = contact[:contact_email]
    @gene_list = []
    @genes.each do |gene|
      @gene_list.push gene[:marker_symbol] if gene[:relevant_status] && gene[:relevant_status][:status]
    end

    @gene_list = word_wrap(@gene_list.join(", "), :line_width => 80)

    @tsv = CSV.generate do |csv|
      csv << %W{Gene Status IMPC IKMC Details}

      @genes.each do |gene|
        impc_site = ''
        impc_site = "http://www.mousephenotype.org/data/genes/#{gene[:mgi_accession_id]}" if gene[:modifier_string] == "is"

        ikmc_site = ''
        ikmc_site = "http://www.knockoutmouse.org/search_results?criteria=#{gene[:mgi_accession_id]}" if gene[:total_cell_count] > 0

        @relevant_status = gene[:relevant_status]

        email_body2 = ERB.new(File.read("#{Rails.root}/app/views/notification_mailer/welcome_email/_#{gene[:relevant_status][:status]}.text.erb")).result(binding) rescue nil

        email_body2 = '' if ! email_body2

        email_body2.gsub!(/\t/, ' ')
        email_body2.gsub!(/\s+/, ' ')

        csv << [
          gene[:marker_symbol].to_s,
          gene[:relevant_status][:status].to_s.humanize,
          impc_site.to_s,
          ikmc_site.to_s,
          email_body2.to_s
        ]
      end
    end

    @email_template = EmailTemplate.find_by_status('welcome_new')

    email_body = ERB.new(@email_template.welcome_body).result(binding) rescue nil

    email_body.gsub!(/\n\n+/, "\n\n")

    attachments['gene_list.csv'] = @tsv

    mail(:to => @contact_email, :subject => "Welcome from the MPI2 (KOMP2) informatics consortium") do |format|
      format.text { render :inline => email_body }
    end
  end

  def status_email(notification)

    return if notification.welcome_email_sent.nil?

    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)

    @relevant_status = {}

    #This sets the relevant_statuses array in the notification
    notification.check_statuses

    return if notification.check_statuses.empty?

    if notification.relevant_statuses.length > 0
      @relevant_status = notification.relevant_statuses.sort_by {|this_status| -this_status[:order_by] }.first
    end

    set_attributes

    @email_template = EmailTemplate.find_by_status(@relevant_status[:status])
    email_body = ERB.new(@email_template.update_body).result(binding) rescue nil

    return if @email_template.blank? || email_body.blank?
    mail(:to => @contact.email, :subject => "Status update for #{@gene.marker_symbol}") do |format|
      format.text { render :inline => email_body }
    end
  end

  def set_attributes

    @modifier_string = "is not"
    @total_cell_count = @gene.es_cells_count

    if(@relevant_status)
      relevant_mi_plan = @relevant_status[:mi_plan_id] ? MiPlan.find(@relevant_status[:mi_plan_id]) : nil
      relevant_mi_attempt = @relevant_status[:mi_attempt_id] ? MiAttempt.find(@relevant_status[:mi_attempt_id]) : nil
      relevant_phenotype_attempt = @relevant_status[:phenotype_attempt_id] ? PhenotypeAttempt.find(@relevant_status[:phenotype_attempt_id]) : nil

      @relevant_production_centre = "unknown production centre"
      if es_cell = TargRep::EsCell.includes(:allele).where("targ_rep_alleles.gene_id = '#{@gene.id}'").first
        @relevant_cell_name = es_cell.name
      end

      if relevant_phenotype_attempt
        @allele_symbol = relevant_phenotype_attempt.allele_symbol.to_s.sub('</sup>', '>').sub('<sup>','<').html_safe
      elsif relevant_mi_attempt
        @allele_symbol = relevant_mi_attempt.allele_symbol.to_s.sub('</sup>', '>').sub('<sup>','<').html_safe
      else
        @allele_symbol = ''
      end

      if (relevant_mi_plan) && (relevant_mi_plan.production_centre != nil)
        @relevant_production_centre = relevant_mi_plan.production_centre.name
      end
      if (relevant_mi_attempt) && (relevant_mi_attempt.es_cell != nil)
        @relevant_cell_name = relevant_mi_attempt.es_cell.name
        @allele_name_suffix = relevant_mi_attempt.es_cell.allele_symbol_superscript_template
      end

      if @gene.mi_plans
        @gene.mi_plans.each do |plan|
          if plan.is_active?
            @modifier_string = "is"
          end
        end
      end
    end
  end

  private :set_attributes

  def send_welcome_email_bulk
    contacts = Contact.joins(:notifications).where('notifications.welcome_email_sent is null').uniq.pluck(:id)

    return if contacts.empty?

    contact_array = []

    contacts.each do |contact_id|
      genes_array = []
      notifications = Notification.where("contact_id = #{contact_id}")

      contact = Contact.find contact_id

      notifications.each do |notification|
        gene = Gene.find notification.gene_id

        modifier_string = "is not"
        modifier_string = "is" if gene.mi_plans.any? {|plan| plan.is_active? }

        relevant_status = gene.relevant_status

        relevant_status = !relevant_status.empty? ? { :status => relevant_status[:status], :date => relevant_status[:date] } :
          { :status => 'unknown', :date => Date.today }

        genes_array.push({
          :marker_symbol => gene.marker_symbol,
          :modifier_string => modifier_string,
          :relevant_status => relevant_status,
          :total_cell_count => gene.es_cells_count,
          :conditional_es_cells_count => gene.conditional_es_cells_count,
          :non_conditional_es_cells_count => gene.non_conditional_es_cells_count,
          :deletion_es_cells_count => gene.deletion_es_cells_count,
          :mgi_accession_id => gene.mgi_accession_id,
          :notification_id => notification.id
        })
      end

      mailer = self.welcome_email_bulk({:contact_email => contact.email, :genes => genes_array})
      next if ! mailer

      ApplicationModel.audited_transaction do

        genes_array.each do |gene|
          notification = Notification.find gene[:notification_id]
          notification.welcome_email_text = mailer.attachments[0].to_s
          notification.welcome_email_sent = Time.now.utc
          #last_email_sent = notification.welcome_email_sent
          notification.save!
        end

        mailer.deliver
      end
    end
  end

  # this is a replacement for the cron:status_emails rake task

  def self.send_status_emails
    excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']

    ApplicationModel.audited_transaction do
      Notification.all.each do |notification|
        next if notification.gene.relevant_status.empty?
        next if excluded_statuses.any? {|status| notification.gene.relevant_status[:status].include? status}
        next if notification.check_statuses.empty?

        mailer = NotificationMailer.status_email(notification)
        notification.last_email_text = mailer.body.to_s
        notification.last_email_sent = Time.now.utc
        notification.save!
        mailer.deliver
      end
    end
  end
end
