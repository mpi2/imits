class NotificationMailer < ActionMailer::Base
  default :from => 'info@mousephenotype.org'
  def welcome_email(notification)
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    @relevant_status = @gene.relevant_status
    @modifier_string = "is not"
    @total_cell_count = @gene.es_cells_count

    if @gene.mi_plans
      @gene.mi_plans.each do |plan|
        if plan.is_active?
          @modifier_string = "is"
        end
      end
    end

    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text
    end
  end

  def status_email(notification)
    # notification.check_status takes into account the timestamps for when the welcome or last email was sent

    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)

    @relevant_status = ""
    @modifier_string = "is not"
    @total_cell_count = @gene.es_cells_count

    notification.check_statuses

    if notification.relevant_statuses.length > 0

      @relevant_status = notification.relevant_statuses.sort_by {|this_status| this_status[:order_by] }.first
      relevant_mi_plan = @relevant_status[:mi_plan_id] ? MiPlan.find(@relevant_status[:mi_plan_id]) : nil
      relevant_mi_attempt = @relevant_status[:mi_attempt_id] ? MiAttempt.find(@relevant_status[:mi_attempt_id]) : nil

      @relevant_production_centre = "unknown production centre"
      @relevant_cell_name = @gene.es_cells.length > 0 ? @gene.es_cells.first.name : ''
      @allele_name_prefix = @gene.marker_symbol
      @allele_name_suffix = @gene.es_cells.length > 0 ? @gene.es_cells.first.allele_symbol_superscript_template : ''

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

      mail(:to => @contact.email, :subject => "Status update for #{@gene.marker_symbol}") do |format|
        format.text
      end
    end
  end

end
