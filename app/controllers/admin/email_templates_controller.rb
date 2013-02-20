class Admin::EmailTemplatesController < Admin::BaseController

  before_filter do
    @title = "Email Templates"
    @tab = "Admin"
  end

  def index
    @email_templates = EmailTemplate.order('status asc')

    respond_to do |format|
      format.html
    end
  end

  def show
    @email_template = EmailTemplate.find(params[:id])
  end

  def preview
    @gene = Gene.search(:marker_symbol_cont => params[:gene_for_preview]).result.first

    if email_template_id = params[:email_template].delete(:id)
      @email_template = EmailTemplate.find(email_template_id)
      @email_template.assign_attributes(params[:email_template])
    else
      @email_template = EmailTemplate.new(params[:email_template])
    end

    @contact = Contact.find_by_email('vvi@sanger.ac.uk')

    @relevant_status = @gene.relevant_status
    set_attributes
    
    begin 
      @welcome_email_body = ERB.new(@email_template.welcome_body).result(binding)
    rescue SyntaxError, NameError

    end

    begin    
      @update_email_body = ERB.new(@email_template.update_body).result(binding) rescue nil
    rescue SyntaxError, NameError

    end
  end

  def create
    @email_template = EmailTemplate.new(params[:email_template])

    @email_template.save
    redirect_to [:admin, @email_template]
  end

  def update
    @email_template = EmailTemplate.find(params[:id])

    @email_template.update_attributes(params[:email_template])
    redirect_to [:admin, @email_template]
  end

  def destroy
    @email_template = EmailTemplate.find(params[:id])
    @email_template.destroy
    redirect_to [:admin, :email_templates], :notice => "The email template was removed successfully."
  end

  private

    def set_attributes

      @modifier_string = "is not"
      @total_cell_count = @gene.es_cells_count

      if(@relevant_status)
        relevant_mi_plan = @relevant_status[:mi_plan_id] ? MiPlan.find(@relevant_status[:mi_plan_id]) : nil
        relevant_mi_attempt = @relevant_status[:mi_attempt_id] ? MiAttempt.find(@relevant_status[:mi_attempt_id]) : nil
        relevant_phenotype_attempt = @relevant_status[:phenotype_attempt_id] ? PhenotypeAttempt.find(@relevant_status[:phenotype_attempt_id]) : nil
    
        @relevant_production_centre = "unknown production centre"
        @relevant_cell_name = @gene.es_cells.length > 0 ? @gene.es_cells.first.name : ''
    
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


end