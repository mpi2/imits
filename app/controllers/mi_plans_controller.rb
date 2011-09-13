# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html, :only => [:gene_selection]
  respond_to :json, :only => [:create]
  before_filter :authenticate_user!

  def gene_selection
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
      q[:marker_symbol_or_mgi_accession_id_ci_in]
        .lines
        .map(&:strip)
        .select{|i|!i.blank?}
        .join("\n")

    @centre_combo_options    = prepare_objects_for_dropdown( Centre.order('name').all, [:id,:name] )
    @consortia_combo_options = prepare_objects_for_dropdown( Consortium.order('name').all, [:id,:name] )
    @priority_combo_options  = prepare_objects_for_dropdown( MiPlanPriority.all, [:id,:name] )
    @interest_status_id      = MiPlanStatus.find_by_name!('Interest').id
  end

  def create
    @mi_plan = MiPlan.new(params[:mi_plan])
    respond_to do |format|
      if @mi_plan.save
        format.json { render :json => @mi_plan, :status => :created }
      else
        format.json { render :json => @mi_plan.errors, :status => 400 }
      end
    end
  end

  private

  def prepare_objects_for_dropdown( objects, attributes )
    prepared_data_array = []
    objects.each do |object|
      prepared_data = {}
      attributes.each do |attribute|
        prepared_data[attribute] = object.send(attribute)
      end
      prepared_data_array.push(prepared_data)
    end
    return prepared_data_array
  end

end
