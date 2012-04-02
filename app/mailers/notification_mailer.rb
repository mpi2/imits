class NotificationMailer < ActionMailer::Base
  default :from => 'htgt@sanger.ac.uk', :bcc => 'gj2@sanger.ac.uk'

  def registration_confirmation(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    @relevant_status = @gene.relevant_status
    @modifier_string = "is not"
    if @gene.mi_plans
      @gene.mi_plans.each do |plan|
        if plan.is_active?
          @modifier_string = "is"
        else
          @modifier_string ||= "is not"
        end
      end
    end

    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text
    end

    @notification = Notification.find(notification.id)
    @notification.welcome_email_text = mail.body
    @notification.save!

  end

end
