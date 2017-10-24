class Reports::NotificationsByGene < Reports::Base

  include Reports::Helper

  class << self
    include Rails.application.routes.url_helpers
  end

  def report_name
    return 'notifications_by_gene_for_idg_' + @consortium if @nominated_type == 'idg'
    return 'notifications_by_gene_for_cmg_' + @consortium if @nominated_type == 'cmg'
    'notifications_by_gene_' + @consortium
  end

  def to(format)
    return @csv if format == 'csv' && @csv
    return @html if format == 'html' && @html
    return nil
  end

  def cache
    ReportCache.transaction do
      ['html', 'csv'].each do |format|
        cache = ReportCache.find_by_name_and_format(report_name, format)
        if ! cache
          cache = ReportCache.new(
          :name => report_name,
          :data => '',
          :format => format
          )
        end

        cache.data = self.to(format)

        return if ! cache.data

        cache.save!
      end
    end
  end

  def initialize_idg(consortium = nil)
    production_centre = nil
    show_eucommtoolscre_data = false
    show_eucommtoolscre_data = true if consortium == 'EUCOMMToolsCre'

    @report = ::NotificationsByGene.new({:show_eucommtoolscre_data => show_eucommtoolscre_data})
    @mi_plan_summary = @report.mi_plan_summary(production_centre, consortium, 'idg')

    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available
    @production_centre = production_centre.blank? ? '' : production_centre
    @consortium = consortium.blank? ? '' : consortium
    @blurb = ""
    @blurb = "#{consortium} " if ! consortium.blank?
    @blurb += "#{production_centre}" if ! production_centre.blank?
    @blurb = "All" if (consortium.blank? && production_centre.blank?) || consortium =~ /all/
    @blurb = "no consortium" if consortium =~ /none/
    @count = @report.blank? ? 0 : @mi_plan_summary.count
#    @pretty_print_statuses = @report.pretty_print_statuses
    @cached = true

    @html = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/_report_with_counts3.html.erb")).result(binding) #rescue nil
    @csv = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/notifications_by_gene.csv.erb")).result(binding) #rescue nil
    @consortium = consortium.to_s
  end


  def initialize_cmg(consortium = nil)
    production_centre = nil
    show_eucommtoolscre_data = false
    show_eucommtoolscre_data = true if consortium == 'EUCOMMToolsCre'

    @report = ::NotificationsByGene.new({:show_eucommtoolscre_data => show_eucommtoolscre_data})
    @mi_plan_summary = @report.mi_plan_summary(production_centre, consortium, 'cmg')

    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available
    @production_centre = production_centre.blank? ? '' : production_centre
    @consortium = consortium.blank? ? '' : consortium
    @blurb = ""
    @blurb = "#{consortium} " if ! consortium.blank?
    @blurb += "#{production_centre}" if ! production_centre.blank?
    @blurb = "All" if (consortium.blank? && production_centre.blank?) || consortium =~ /all/
    @blurb = "no consortium" if consortium =~ /none/
    @count = @report.blank? ? 0 : @mi_plan_summary.count
#    @pretty_print_statuses = @report.pretty_print_statuses
    @cached = true

    @html = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/_report_with_counts3.html.erb")).result(binding) #rescue nil
    @csv = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/notifications_by_gene.csv.erb")).result(binding) #rescue nil
    @consortium = consortium.to_s
  end

  def initialize_default(consortium = nil)
    production_centre = nil
    show_eucommtoolscre_data = false
    show_eucommtoolscre_data = true if consortium == 'EUCOMMToolsCre'

    @report = ::NotificationsByGene.new({:show_eucommtoolscre_data => show_eucommtoolscre_data})
    @mi_plan_summary = @report.mi_plan_summary(production_centre, consortium)
    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available
    @production_centre = production_centre.blank? ? '' : production_centre
    @consortium = consortium.blank? ? '' : consortium
    @blurb = ""
    @blurb = "#{consortium} " if ! consortium.blank?
    @blurb += "#{production_centre}" if ! production_centre.blank?

    @blurb = "All" if (consortium.blank? && production_centre.blank?) || consortium =~ /all/
    @blurb = "no consortium" if consortium =~ /none/

    @count = @report.blank? ? 0 : @mi_plan_summary.count
#    @pretty_print_statuses = @report.pretty_print_statuses
    @cached = true

    @html = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/_report_with_counts3.html.erb")).result(binding) #rescue nil
    @csv = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/notifications_by_gene.csv.erb")).result(binding) #rescue nil
    @consortium = consortium.to_s
  end

  def initialize(consortium = nil, nominated_type = false)
    @nominated_type = nominated_type
    if nominated_type == 'idg'
      initialize_idg consortium
    elsif nominated_type == 'cmg'
      initialize_cmg consortium
    else
      initialize_default consortium
    end
  end

end
