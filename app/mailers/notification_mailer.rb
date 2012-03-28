class NotificationMailer < ActionMailer::Base
  default :from => 'htgt@sanger.ac.uk', :bcc => 'gj2@sanger.ac.uk'

  def registration_confirmation(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    if @gene.mi_plans
      @gene.mi_plans.each do |plan|
        if plan.is_active?
          @modifier_string = "is"
        else
          @modifier_string ||= "is not"
        end
      end
    else
      @modifier_string = "is not"
    end
    
    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text
    end
  end
  
end
