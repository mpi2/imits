class NotificationMailer < ActionMailer::Base
  default :from => 'htgt@sanger.ac.uk', :bcc => 'gj2@sanger.ac.uk'

  def registration_confirmation(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered")
  end
  
end
