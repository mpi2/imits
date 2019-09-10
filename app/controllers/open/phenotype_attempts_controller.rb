# encoding: utf-8

class Open::PhenotypeAttemptsController < OpenApplicationController

  respond_to :html, :json
  respond_to :json, :only => :index

  def index
    respond_to do |format|
      set_centres_and_consortia
      format.html do
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
        @access = false
        render 'phenotype_attempts/index' # renders the apps/views/phenotype_attempts/index.html.erb view.
      end

      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def show
    @phenotype_attempt = Public::PhenotypeAttempt.find(params[:id])   
    @parent_colony = Colony.find_by_name(@phenotype_attempt.parent_colony_name)
    if @phenotype_attempt.report_to_public
      @mi_attempt = @phenotype_attempt.mi_attempt
      respond_with @phenotype_attempt
    else
      redirect_to open_phenotype_attempts_path,  :alert => "No mouse phenotyping exists with id #{params[:id]}."
    end
  end

  def data_for_serialized(format)

    pp_search_options = { 'phenotype_attempt_id'             => 'phenotype_attempt_id',
                          'marker_symbol'                    => 'marker_symbol',
                          'colony_name'                      => 'colony_name',
                          'status_name'                      => 'status_name',
                          'production_centre_name'           => 'production_centre_name',
                          'consortium_name'                  => 'consortium_name',
                          'parent_colony_name'               => 'parent_colony_name',
                          'rederivation_started'             => 'rederivation_started',
                          'rederivation_complete'            => 'rederivation_complete',
                          'phenotyping_experiments_started'  => 'phenotyping_experiments_started',
                          'phenotyping_started'              => 'phenotyping_started',
                          'phenotyping_complete'             => 'phenotyping_complete',
                          'colony_background_strain_name'    => 'colony_background_strain_name',
                          'mouse_allele_type'                => 'parent_colony_allele_type',
                          'allele_name'                      => 'parent_colony_allele_name',
                          'allele_mgi_accession_id'          => 'parent_colony_allele_mgi_accession_id',
                          'is_active'                        => 'is_active',
                          'report_to_public'                 => 'report_to_public'
                          }

    mam_search_options = {
                          'phenotype_attempt_id'             => 'phenotype_attempt_id',
                          'marker_symbol'                    => 'marker_symbol',
                          'colony_name'                      => 'colony_name_or_colony_phenotyping_productions_colony_name',
                          'production_centre_name'           => 'production_centre_name_or_colony_phenotyping_productions_mi_plan_production_centre_name',
                          'consortium_name'                  => 'consortium_name_or_colony_phenotyping_productions_mi_plan_consortium_name',
                          'mouse_allele_mod_id'              => 'parent_colony_mouse_allele_mod_id',
                          'parent_colony_name'               => 'parent_colony_name',
                          'rederivation_started'             => 'rederivation_started',
                          'rederivation_complete'            => 'rederivation_complete',
                          'number_of_cre_matings_started'    => 'number_of_cre_matings_started',
                          'number_of_cre_matings_successful' => 'number_of_cre_matings_successful',
                          'phenotyping_experiments_started'  => 'colony_phenotyping_productions_phenotyping_experiments_started',
                          'phenotyping_started'              => 'colony_phenotyping_productions_phenotyping_started',
                          'phenotyping_complete'             => 'colony_phenotyping_productions_phenotyping_complete',
                          'colony_background_strain_name'    => 'colony_background_strain_name_or_colony_phenotyping_productions_colony_background_strain_name',
                          'mouse_allele_type'                => 'colony_allele_type',
                          'allele_name'                      => 'colony_allele_name',
                          'allele_mgi_accession_id'          => 'colony_allele_mgi_accession_id',
                          'cre_excision_required'            => 'cre_excision',
                          'tat_cre'                          => 'tat_cre',
                          'deleter_strain_name'              => 'deleter_strain_name',
                          'is_active'                        => 'is_active',
                          'report_to_public'                 => 'report_to_public'
                         }

   pp_translation_options = {
                          'mi_plan_'                  => 'mi_plan_',
                          'mi_attempt_'               => 'parent_colony_mi_attempt_',
                          'phenotyping_productions_'  => '',
                          'status_stamps_'            => 'status_stamps_'
                        }

   mam_translation_options = {
                          'mi_plan_'                  => 'mi_plan_',
                          'distribution_centres_'     => 'colony_distribution_centres_',
                          'mi_attempt_'               => 'parent_colony_mi_attempt_',
                          'phenotyping_productions_'  => 'colony_phenotyping_productions_',
                          'status_stamps_'            => 'status_stamps_or_colony_phenotyping_productions_status_stamps_'
                        }


    all_params = params.dup

    if params['q']
      params['q'].stringify_keys!
      params.merge!(params['q'])
      params.delete('q')
    end

    extended_response = params[:extended_response].to_s
    params[:extended_response] = 'true' unless params.has_key?(:extended_response)
    total_count = 0

    params[:per_page] = params.has_key?(:per_page) ? params[:per_page].to_i : 20
    per_page = params[:per_page].to_i

    pp_params = params.dup
    mam_params = params.dup

    pa = []
    params.each do |p, value|
      md_string = /(.+?)(_not_eq|_eq|_not_equal_any|_cont|_in\[\]|_in|_ci_in|_ci_in\[\]|_gteq|_gt|_lteq|_lt|_true|_false|_not_null|_null)$/.match(p)

      if md_string
        md_split = md_string[1].split('_or_')
        pp_param  = []
        mam_param = []

        pp_params.delete(p)
        mam_params.delete(p)

        md_split.each do |md|

          sub_md = /^(#{pp_translation_options.keys.join('|')})(.+)$/.match(md)
          if sub_md
            pp_param << pp_translation_options[sub_md[1]] + sub_md[2]
          elsif ['cre_excision_required', 'tat_cre'].include?(md)
            if !['_null', '_false'].include?(md_string[2]) && value != 'false'
              pp_params[:skip] = true
            end
          elsif ( md == 'deleter_strain_name' && !value.blank? ) || ( md =~ /distribution_centres/ )
            pp_params[:skip] = true
          elsif pp_search_options.keys.include?(md)
            pp_param << pp_search_options[md]
          else
            pp_param  = []
            break
          end
        end

        md_split.each do |md|
          sub_md = /^(#{mam_translation_options.keys.join('|')})(.+)$/.match(md)
          if sub_md
            mam_param << mam_translation_options[sub_md[1]].gsub('_or_', "_#{sub_md[2]}_or_") + sub_md[2]
          elsif mam_search_options.keys.include?(md)
            mam_param << mam_search_options[md]
          elsif md == 'status_name'
            value = value.is_a?(Array) ? value : [value]
            if value.any?{ |v| ['Phenotyping Started', 'Phenotyping Complete'].include?(v)}
              mam_param << 'status_name_or_colony_phenotyping_productions_status_name'
            else
              mam_param << 'status_name'
            end
          else
            mam_param  = []
            break
          end
        end

        pp_params[ pp_param.join('_or_') + md_string[2] ] = value unless pp_param.blank?
        mam_params[ mam_param.join('_or_') + md_string[2] ] = value unless mam_param.blank?
      end
    end


    pp_params['parent_colony_mi_attempt_id_not_null'] = true
    pp_params[:per_page] = per_page

    # Phenotyped Alleles produced via MiAttempt (Micro-injection)
    unless pp_params.has_key?(:skip) &&  pp_params[:skip] == true
      params.delete_if{|key,value| params.has_key?(key)}
      pp_params.each{|key, value| params[key] = value}
      pp = super(format, 'id asc', Public::PhenotypingProduction, :public_search, true)
      pp["open_phenotype_attempts"].each{|p| pa << Public::PhenotypeAttempt.find(p['phenotype_attempt_id']).attributes} if pp.has_key?("open_phenotype_attempts")
      total_count += pp['total']
      per_page = per_page -  pp["open_phenotype_attempts"].length
      if per_page > 0
        mam_params[:page] = (((mam_params[:page].to_i * mam_params[:per_page].to_i) - 1 - pp['total']) / mam_params[:per_page].to_i) + 1 if mam_params.has_key?(:page)
      end
    end

    params.delete_if{|key,value| params.has_key?(key)}
    mam_params.each{|key, value| params[key] = value}
    mam = super(format, 'id asc', Public::MouseAlleleMod, :public_search, true)
    total_count += mam['total'] ? (mam['total'] / 20) * 20 : 0

    if per_page > 0 && mam.has_key?('total')
      # Phenotyped Alleles produced via MouseAlleleModification (Micro-injection)
      mam["open_phenotype_attempts"].each{|m| pa << Public::PhenotypeAttempt.find(m['phenotype_attempt_id']).attributes} if mam.has_key?("open_phenotype_attempts")
    end

    params.delete_if{|key,value| params.has_key?(key)}
    all_params.each{|key, value| params[key] = value}

    if extended_response == 'true'
      return {"open_phenotype_attempts" => pa.as_json, "success"=>true,"total"=> total_count}.as_json
    else
      return pa
    end

  end
  protected :data_for_serialized
end