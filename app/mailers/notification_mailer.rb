class NotificationMailer < ActionMailer::Base
  default :from => 'gj2@sanger.ac.uk', :bcc => 'garanjones@hotmail.com'

  def welcome_email(notification)
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
    @total_cell_count = (@gene.conditional_es_cells_count || 0) + (@gene.non_conditional_es_cells_count || 0) + (@gene.deletion_es_cells_count || 0)

    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text
    end

    @notification = Notification.find(notification.id)
    @notification.welcome_email_text = mail.body
    @notification.save!

  end
  
  def status_email(notification)
    # notification.check_status takes into account the timestamps for when the welcome or last email was sent
    notification.check_statuses
    
    @relevant_status = notification.relevant_statuses.sort_by {|this_status| this_status[:order_by] }.first
    
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    
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
    @total_cell_count = (@gene.conditional_es_cells_count || 0) + (@gene.non_conditional_es_cells_count || 0) + (@gene.deletion_es_cells_count || 0)
    
    mail(:to => @contact.email, :subject => "Status update on Gene #{@gene.marker_symbol}") do |format|
      format.text
    end
    
    @notification = Notification.find(notification.id)
    @notification.last_email_text = mail.body
    @notification.save!
    
  end

end
