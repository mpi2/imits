class NotificationMailer < ActionMailer::Base
  default :from => 'info@mousephenotype.org'
  def welcome_email(notification)
    
    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    @relevant_status = @gene.relevant_status
    
    set_attributes(notification)
    mail(:to => @contact.email, :subject => "Gene #{@gene.marker_symbol} updates registered") do |format|
      format.text
    end
  end

  def status_email(notification)

    @contact = Contact.find(notification.contact_id)
    @gene = Gene.find(notification.gene_id)
    
    #This sets the relevant_statuses array in the notification
    notification.check_statuses
    if notification.relevant_statuses.length > 0
      @relevant_status = notification.relevant_statuses.sort_by {|this_status| -this_status[:order_by] }.first
    end
    
    set_attributes(notification)
    mail(:to => @contact.email, :subject => "Status update for #{@gene.marker_symbol}") do |format|
      format.text
    end
  end

  def set_attributes(notification)

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
end
