class NotificationMailer < ActionMailer::Base
  default :from => 'team87@sanger.ac.uk', :bcc => 'gj2@sanger.ac.uk'
  def welcome_email(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    @relevant_status = @gene.relevant_status
    @modifier_string = "is not"
    if @gene.mi_plans
      @gene.mi_plans.each do |plan|
        if plan.is_active?
          @modifier_string = "is"
        end
      end
    end
    @total_cell_count = @gene.es_cells_count
    
    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text
    end
  end
  
  def status_email(notification)
    # notification.check_status takes into account the timestamps for when the welcome or last email was sent
    
    @contact = Contact.find(notification.contact_id) 
    @gene = Gene.find(notification.gene_id)
    @relevant_status = ""
    
    notification.check_statuses

    if notification.relevant_statuses.length > 0
      @relevant_status = notification.relevant_statuses.sort_by {|this_status| this_status[:order_by] }.first
      @modifier_string = "is not"
        if @gene.mi_plans
          @gene.mi_plans.each do |plan|
            if plan.is_active?
              @modifier_string = "is"
            end
          end
        end
      @total_cell_count = @gene.es_cells_count
    
      mail(:to => @contact.email, :subject => "Status update for #{@gene.marker_symbol}") do |format|
        format.text
      end
    end
  end

end
