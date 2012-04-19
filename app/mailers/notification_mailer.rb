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
    
    @contact = Contact.find(notification.contact_id) 
    @gene = Gene.find(notification.gene_id)
    
    notification.check_statuses
    
    logger.debug "++++++++++++"
    logger.debug @contact.inspect
    logger.debug @gene.inspect
    logger.debug notification.inspect
    logger.debug notification.relevant_statuses.length
    logger.debug "************"
    
    if notification.relevant_statuses.length > 0
      @relevant_status = notification.relevant_statuses.sort_by {|this_status| this_status[:order_by] }.first

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
    
      mail(:subject => "Status update for #{@gene.marker_symbol}", :to => @contact.email)
    end
  end

end
