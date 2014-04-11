
class NotificationMailer < ActionMailer::Base

  include ActionView::Helpers::TextHelper

  default :from => 'info@mousephenotype.org'

  def welcome_email(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    @relevant_status = @gene.relevant_status
    @relevant_status[:status] ||= ''

    set_attributes

    @email_template = EmailTemplate.find_by_status(@relevant_status[:status])
    email_body = ERB.new(@email_template.welcome_body).result(binding) rescue nil

    email_body.gsub!(/\r/, "\n")
    email_body.gsub!(/\n\n+/, "\n\n")
    email_body.gsub!(/\n\n\s+\n\n/, "\n\n")

    Rails.logger.info('#### NotificationMailer::welcome_email start')
    Rails.logger.info('#### @contact.email: #{@contact.email}')
    Rails.logger.info('#### @gene.marker_symbol: #{@gene.marker_symbol}')
    Rails.logger.info('#### email_body: #{email_body}')
    Rails.logger.info('#### NotificationMailer::welcome_email end')

    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text { render :inline => email_body }
    end
  end

  def welcome_email_bulk(contact)
    wrap_details = false
    hyperlink_fn_separator = ','  # differs between open-office & excel

    @genes = contact[:genes]
    @contact_email = contact[:contact_email]
    @gene_list = []
    @genes.each do |gene|
      @gene_list.push gene[:marker_symbol]
    end

    @gene_list.sort!

    @gene_list = word_wrap(@gene_list.join(", "), :line_width => 80)

    @csv = CSV.generate do |csv|
      headings = ['Marker symbol', 'Mouse production status', 'Link to IMPC', 'Link to IKMC', 'Click to IMPC', 'Click to IKMC', 'IMPC Status Details']

      csv << headings

      @genes.each do |gene|
        impc_site = ''
        impc_site = "http://www.mousephenotype.org/data/genes/#{gene[:mgi_accession_id]}" if gene[:modifier_string] == "is"
        impc_site_fn = ''
        impc_site_fn = "=HYPERLINK(\"#{impc_site}\" #{hyperlink_fn_separator} \"Click here\")" if impc_site.length > 0

        ikmc_site = ''
        ikmc_site = "http://www.knockoutmouse.org/search_results?criteria=#{gene[:mgi_accession_id]}" if gene[:total_cell_count] > 0
        ikmc_site_fn = ''
        ikmc_site_fn = "=HYPERLINK(\"#{ikmc_site}\" #{hyperlink_fn_separator} \"Click here\")" if ikmc_site.length > 0

        @relevant_status = gene[:relevant_status]
        #@relevant_status[:status] ||= ''

        email_body2 = ERB.new(File.read("#{Rails.root}/app/views/notification_mailer/welcome_email/_#{gene[:relevant_status][:status]}.text.erb")).result(binding) rescue nil

        email_body2 = '' if ! email_body2

        email_body2.gsub!(/\s+/, ' ')

        comments = ''
        if gene[:relevant_status][:status].to_s =~ /not assigned for IMPC production/i && ikmc_site.length > 0
          comments = "No IMPC plans - but gene has #{gene[:total_cell_count]} IKMC clones"
        end

        email_body2 = word_wrap(email_body2, :line_width => 35) if wrap_details && email_body2 && email_body2.length > 0

        status = gene[:relevant_status][:status].to_s.humanize.titleize
        status = status.gsub(/\s+es\s+/i, ' ES ')
        status = status.gsub(/\s+qc\s+/i, ' QC ')
        status = status.gsub(/\s+impc\s+/i, ' IMPC ')

        row = [
          gene[:marker_symbol].to_s,
          status,
          impc_site.to_s,
          ikmc_site.to_s,
          impc_site_fn.to_s,
          ikmc_site_fn.to_s
        ]

        row.push email_body2.to_s if email_body2.to_s.length > 0
        row.push comments.to_s if email_body2.to_s.length == 0 && comments.to_s.length > 0

        csv << row
      end
    end

    @email_template = EmailTemplate.find_by_status('welcome_template')

    email_body = ERB.new(@email_template.welcome_body).result(binding) rescue nil

    email_body.gsub!(/\n\n+/, "\n\n")

    attachments['gene_list.csv'] = @csv

    Rails.logger.info('#### NotificationMailer::welcome_email_bulk start')
    Rails.logger.info('#### @contact_email: #{@contact_email}')
    Rails.logger.info('#### email_body: #{email_body}')
    Rails.logger.info('#### NotificationMailer::welcome_email_bulk end')

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

    Rails.logger.info('#### NotificationMailer::status_email start')
    Rails.logger.info('#### @contact.email: #{@contact.email}')
    Rails.logger.info('#### @gene.marker_symbol: #{@gene.marker_symbol}')
    Rails.logger.info('#### email_body: #{email_body}')
    Rails.logger.info('#### NotificationMailer::status_email end')

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

  def get_relevant_status(gene)
    rs = gene.relevant_status

    relevant_status = { :status => 'not found', :date => Date.today }

    if rs.empty?
      status = ''
      status = 'not assigned for IMPC production' if ! gene.mi_plans || gene.mi_plans.size == 0
      relevant_status = { :status => status, :date => Date.today }
    else
      relevant_status = { :status => rs[:status], :date => rs[:date] }
    end

    relevant_status
  end

  private :get_relevant_status

  def send_welcome_email_bulk
    contacts = Contact.joins(:notifications).where('notifications.welcome_email_sent is null').uniq.pluck(:id)

    return if contacts.empty?

    contact_array = []

    contacts.each do |contact_id|
      genes_array = []
      notifications = Notification.where("contact_id = #{contact_id} and welcome_email_sent is null")

      contact = Contact.find contact_id

      notifications.each do |notification|
        gene = Gene.find notification.gene_id

        modifier_string = "is not"
        modifier_string = "is" if gene.mi_plans.any? {|plan| plan.is_active? }

        relevant_status = get_relevant_status(gene)

        genes_array.push({
          :marker_symbol => gene.marker_symbol,
          :modifier_string => modifier_string,
          :relevant_status => relevant_status,
          :total_cell_count => gene.es_cells_count,
          :mgi_accession_id => gene.mgi_accession_id,
          :notification_id => notification.id
        })
      end

      mailer = NotificationMailer.welcome_email_bulk({:contact_email => contact.email, :genes => genes_array})
      next if ! mailer

      ApplicationModel.audited_transaction do

        genes_array.each do |gene|
          notification = Notification.find gene[:notification_id]
          notification.welcome_email_text = mailer.text_part.body.to_s
          notification.welcome_email_sent = Time.now.utc
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

  def get_production_centre_report(production_centre = nil)
    @report = ::NotificationsByGene.new
    @mi_plan_summary = @report.mi_plan_summary(production_centre)
    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @pretty_print_statuses = @report.pretty_print_statuses
    @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available

    if ! production_centre
      @mi_plan_summary = @mi_plan_summary.to_a.reject do |rec|
        @pretty_print_non_assigned_mi_plans[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_assigned_mi_plans[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_aborted_mi_attempts[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_mi_attempts_in_progress[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_mi_attempts_genotype_confirmed[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_statuses[rec['marker_symbol']].to_s.length > 0
      end
    end

    template = IO.read("#{Rails.root}/app/views/v2/reports/mi_production/notifications_by_gene.csv.erb")

    template.gsub!(/\s+\<\% end \%\>/, '<% end %>')
    template.gsub!(/GLT Mice\s+/, 'GLT Mice')

    ERB.new(template).result(binding) rescue nil
  end

  def send_production_centre_email(production_centre, email, bcc = nil)
    @email_template = EmailTemplate.find_by_status!('production_centre_report')

    @contact_email = email
    @production_centre = production_centre

    @csv2 = @@csv2
    @csv1 = get_production_centre_report production_centre

    @genes_production_count = @csv1.count("\n") - 1
    @genes_idle_count = @csv2.count("\n") - 1

    email_body = ERB.new(@email_template.update_body).result(binding) rescue nil
    email_body.gsub!(/\r/, "\n")
    email_body.gsub!(/\n\n+/, "\n\n")
    email_body.gsub!(/\n\n\s+\n\n/, "\n\n")

    attachments['production_centre_gene_list.csv'] = @csv1 if @genes_production_count > 0
    attachments['production_centre_gene_list_idle.csv'] = @csv2

    mail(:to => email, :subject => "iMits Production Centre #{production_centre} Report", :bcc => bcc) { |format| format.text { render :inline => email_body } }.deliver if bcc
    mail(:to => email, :subject => "iMits Production Centre #{production_centre} Report") { |format| format.text { render :inline => email_body } }.deliver if ! bcc
  end

  def send_admin_email(email, subject, body)
    mail(:to => email, :subject => subject) do |format|
      format.text { render :inline => body }
    end.deliver
  end

  def send_production_centre_emails
    config = YAML.load_file File.join(Rails.root, 'config', 'production_centre_contacts.yml')

    contacts = config['contacts']
    bcc = config['bcc']

    @@csv2 = get_production_centre_report

    missing = []

    contacts.keys.each do |centre|
      if contacts[centre]
        list = contacts[centre].split('|')
        list.each do |email|
          NotificationMailer.send_production_centre_email(centre, email, bcc)
        end
      else
        missing.push centre
      end
    end
  end

end
