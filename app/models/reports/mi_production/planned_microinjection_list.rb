# encoding: utf-8

class Reports::MiProduction::PlannedMicroinjectionList < Reports::Base

  def _report_name; @report_name_str; end

  def initialize(consortium='')
    params={}
    if ! consortium.blank?
      consortium_id = Consortium.find_by_name!(consortium).id
      params={:consortium_id => consortium_id}
    end
    @report = planned_microinjection_list(params)
    @report_name_str = "planned_microinjection_list_#{consortium}"
  end

  def planned_microinjection_list(params={})

    report = generate_planned_mi_list_report( params )

    return nil if report.nil?

    report.add_column('Best Status') { |row| IntermediateReport.find_by_mi_plan_id(row.data['ID']).try(:overall_status) }
    report.add_column('Reason for Inspect/Conflict') { |row| MiPlan.find(row.data['ID']).reason_for_inspect_or_conflict }
    report.remove_columns(['ID'])

    mis_by_gene = {
      'Non-Assigned Plans' => Gene.pretty_print_non_assigned_mi_plans_in_bulk,
      'Assigned Plans'     => Gene.pretty_print_assigned_mi_plans_in_bulk,
      'Aborted MIs'      => Gene.pretty_print_aborted_mi_attempts_in_bulk,
      'MIs in Progress'  => Gene.pretty_print_mi_attempts_in_progress_in_bulk,
      'GLT Mice'         => Gene.pretty_print_mi_attempts_genotype_confirmed_in_bulk
    }

    mis_by_gene.each do |title,store|
      report.add_column(title) do |row|
        data = store[row.data['Marker Symbol']]
        data.gsub!('<br/>',' ') if !data.nil?
        data
      end
    end

    return report
  end

  def generate_planned_mi_list_report( params={} )
    report_column_order_and_names = {
      'id'                      => 'ID',
      'consortium.name'         => 'Consortium',
      'sub_project.name'        => 'SubProject',
      'is_bespoke_allele'       => 'Bespoke',
      'phenotype_only'          => 'Phenotype only?',
      'production_centre.name'  => 'Production Centre',
      'gene.marker_symbol'      => 'Marker Symbol',
      'gene.mgi_accession_id'   => 'MGI Accession ID',
      'priority.name'           => 'Priority',
      'status.name'             => 'Plan Status'
    }

    report_options = {
      :only       => report_column_order_and_names.keys,
      :conditions => params && params[:consortium_id] ? {:consortium_id => params[:consortium_id]} : nil,
      :include    => {
        :sub_project        => { :only => [:name] },
        :consortium         => { :only => [:name] },
        :production_centre  => { :only => [:name] },
        :gene               => { :only => [:marker_symbol,:mgi_accession_id] },
        :priority           => { :only => [:name] },
        :status             => { :only => [:name] }
      },
      :transforms => lambda do |r|
        r["is_bespoke_allele"] = r.is_bespoke_allele ? 'Yes' : 'No'
        r["phenotype_only"] = r.phenotype_only ? 'Yes' : 'No'
      end
    }

    report = MiPlan.report_table( :all, report_options )

    return nil if report.size == 0

    report.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
    report.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )
    report.sort_rows_by!('Marker Symbol', :order => :ascending)

    return report
  end

  def to_csv
    @report && @report.data && @report.data.size > 0 ? @report.to_csv : ''
  end

  def cache
    ReportCache.transaction do
      cache = ReportCache.find_by_name_and_format(_report_name, 'csv')
      if ! cache
        cache = ReportCache.new(
          :name => _report_name,
          :data => '',
          :format => 'csv'
          )
      end

      next if ! self.respond_to?('to_csv')

      cache.data = self.to_csv
      cache.save!
    end
  end

  def self.cache_all
    Consortium.all.each do |consortium|
      Reports::MiProduction::PlannedMicroinjectionList.new(consortium.name).cache
    end
    # do 'All'
    Reports::MiProduction::PlannedMicroinjectionList.new.cache
  end

end
