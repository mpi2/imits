
class NotificationMailer < ActionMailer::Base

  include ActionView::Helpers::TextHelper

  default :from => 'impc-imits@ebi.ac.uk'

  def get_production_centre_report(production_centre = nil)
    @report = ::NotificationsByGene.new({:show_eucommtoolscre_data => false})
    @mi_plan_summary = @report.mi_plan_summary(production_centre)
    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available

    if ! production_centre
      @mi_plan_summary = @mi_plan_summary.to_a.reject do |rec|
        @pretty_print_non_assigned_mi_plans[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_assigned_mi_plans[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_aborted_mi_attempts[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_mi_attempts_in_progress[rec['marker_symbol']].to_s.length > 0 ||
        @pretty_print_mi_attempts_genotype_confirmed[rec['marker_symbol']].to_s.length > 0
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
