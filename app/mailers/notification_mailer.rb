require 'pp'

class NotificationMailer < ActionMailer::Base

  include ActionView::Helpers::TextHelper

  default :from => 'info@mousephenotype.org'

  def welcome_email(notification)
    genes_array = []
    notifications = Notification.where("contact_id = #{notification.contact_id} and welcome_email_sent is null")

    contact = Contact.find contact_id

    notifications.each do |notification|
      #next if notification.welcome_email_sent

      gene = Gene.find notification.gene_id

      modifier_string = "is not"
      modifier_string = "is" if gene.mi_plans.any? {|plan| plan.is_active? }

      #gene.mi_plans.each do |plan|
      #  raise "#### found active #{gene.marker_symbol}!" if plan.is_active?
      #end

      relevant_status = gene.relevant_status
      relevant_status = ! relevant_status.empty? ? { :status => relevant_status[:status], :date => relevant_status[:date] } :
      { :status => 'unknown', :date => Date.today }

      # puts "#### relevant_status 2:"
      #  pp relevant_status

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
    if mailer
      ApplicationModel.audited_transaction do

        genes_array.each do |gene|
          notification = Notification.find gene[:notification_id]
          notification.welcome_email_text = mailer.body.to_s
          notification.welcome_email_sent = Time.now.utc
          notification.save!
        end

        mailer.deliver
      end
    end
  end

  def welcome_email_bulk(contact)
    @genes = contact[:genes]
    @contact_email = contact[:contact_email]
    @gene_list = []
    @genes.each do |gene|
      @gene_list.push gene[:marker_symbol] if gene[:relevant_status] && gene[:relevant_status][:status]
    end

    # pp @gene_list

    # pp contact

    #puts "#### @genes:"
    #pp @genes

    @gene_list = word_wrap(@gene_list.join(", "), :line_width => 80)

 #   @tsv = "Gene\tStatus\tIMPC\tIKMC\tDetails\n"

    @tsv = CSV.generate do |csv|

      csv << %W{Gene Status IMPC IKMC Details}

      @genes.each do |gene|
        impc_site = ''
        impc_site = "http://www.mousephenotype.org/data/genes/#{gene[:mgi_accession_id]}" if gene[:modifier_string] == "is"

        ikmc_site = ''
        ikmc_site = "http://www.knockoutmouse.org/search_results?criteria=#{gene[:mgi_accession_id]}" if gene[:total_cell_count] > 0

        #<%= render :partial => "notification_mailer/welcome_email/" + gene[:relevant_status][:status].to_s %>
        @relevant_status = gene[:relevant_status]
        # email_template2 = EmailTemplate.find_by_status(gene[:relevant_status][:status])

        #  puts "#### found template #{gene[:relevant_status][:status]}" if email_template2

        #email_body2 = ERB.new(email_template2.welcome_body).result(binding) rescue nil

        #/nfs/users/nfs_r/re4/dev/imits3/app/views/notification_mailer/welcome_email/_aborted_es_cell_qc_failed.text.erb

        #if File.exist?("#{Rails.root}/app/views/notification_mailer/welcome_email/_#{gene[:relevant_status][:status]}.text.erb")
        #  puts "#### found template #{gene[:relevant_status][:status]}"
        #end

        email_body2 = ERB.new(File.read("#{Rails.root}/app/views/notification_mailer/welcome_email/_#{gene[:relevant_status][:status]}.text.erb")).result(binding) rescue nil

        #email_body2 = '' if

        if email_body2 && email_body2.length < 10 && File.exist?("#{Rails.root}/app/views/notification_mailer/welcome_email/_#{gene[:relevant_status][:status]}.text.erb")
          puts "#### found template #{gene[:relevant_status][:status]}"
          email_body2 = ''
        end

        email_body2 = '' if ! email_body2

        email_body2.gsub!(/\t/, ' ')
        email_body2.gsub!(/\s+/, ' ')

        pp email_body2

        #@tsv += gene[:marker_symbol].to_s + "\t" +
        #gene[:relevant_status][:status].to_s + "\t" +
        #impc_site.to_s + "\t" +
        #ikmc_site.to_s + "\t" +
        #email_body2.to_s + "\n"

        #csv << ["row", "of", "CSV", "data"]
        #csv << ["another", "row"]

        csv << [
          gene[:marker_symbol].to_s,
          gene[:relevant_status][:status].to_s,
          impc_site.to_s,
          ikmc_site.to_s,
          email_body2.to_s
        ]
      end
    end

    @email_template = EmailTemplate.find_by_status('welcome_new')

    #pp @email_template

    email_body = ERB.new(@email_template.welcome_body).result(binding) rescue nil

    #return if ! email_body

    email_body.gsub!(/\n\n+/, "\n\n")

    #  raise "#### send email!"

    attachments['gene_list.tsv'] = @tsv
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

        #raise "#### true!" if modifier_string == "is"
        #
        #gene.mi_plans.each do |plan|
        #  raise "#### found active #{gene.marker_symbol}!" if plan.is_active?
        #end

        relevant_status = gene.relevant_status

        #if relevant_status.empty?
        #  puts "#### problem: #{gene.marker_symbol}"
        #end

        relevant_status = !relevant_status.empty? ? { :status => relevant_status[:status], :date => relevant_status[:date] } : #nil
        { :status => 'unknown', :date => Date.today }

        #puts "#### relevant_status X:"
        #pp relevant_status

        #if relevant_status[:status] =~ /abort/i
        #  puts "#### ignore #{gene.marker_symbol}"
        #  next
        #end

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
          notification.welcome_email_text = mailer.body.to_s
          notification.welcome_email_sent = Time.now.utc
          notification.save!
        end

        mailer.deliver
      end
    end
  end

  #desc 'Generate status emails'
  #task 'cron:status_emails' => [:environment] do
  #ApplicationModel.audited_transaction do
  #  @excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']
  #  notifications = Notification.all
  #  notifications.each do |this_notification|
  #    if !this_notification.gene.relevant_status.empty?
  #      if !@excluded_statuses.any? {|status| this_notification.gene.relevant_status[:status].include? status}
  #        if !this_notification.check_statuses.empty?
  #          mailer = NotificationMailer.status_email(this_notification)
  #          this_notification.last_email_text = mailer.body.to_s
  #          this_notification.last_email_sent = Time.now.utc
  #          this_notification.save!
  #          mailer.deliver
  #        end
  #      end
  #    end
  #  end
  #end

  #def self.send_status_emails_old
  #  ApplicationModel.audited_transaction do
  #    @excluded_statuses = ['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted']
  #    notifications = Notification.all
  #    puts "#### 1"
  #    notifications.each do |this_notification|
  #      puts "#### 2"
  #      if !this_notification.gene.relevant_status.empty?
  #        puts "#### 3"
  #        if !@excluded_statuses.any? {|status| this_notification.gene.relevant_status[:status].include? status}
  #          puts "#### 4"
  #          if !this_notification.check_statuses.empty?
  #            puts "#### 5"
  #            mailer = NotificationMailer.status_email(this_notification)
  #            this_notification.last_email_text = mailer.body.to_s
  #            this_notification.last_email_sent = Time.now.utc
  #            this_notification.save!
  #            mailer.deliver
  #          end
  #        end
  #      end
  #    end
  #  end
  #end

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
