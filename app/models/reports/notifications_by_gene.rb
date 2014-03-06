require 'pp'

class Reports::NotificationsByGene < Reports::Base

  include Reports::Helper

  class << self
    include Rails.application.routes.url_helpers
  end

  def report_name
    return 'notifications_by_gene_for_idg_' + @consortium if @idg
    'notifications_by_gene_' + @consortium
  end

  def to(format)
    return @csv if format == 'csv' && @csv
    return @html if format == 'html' && @html
    return nil
  end

  def cache
    #puts "#### cache: report_name: #{report_name}"

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

        #pp cache
        #pp cache.data

        #puts "#### ignoring #{report_name} (#{format})" if ! cache.data
        return if ! cache.data

        cache.save!
      end
    end
  end

  #def to_csv
  #  @csv
  #end
  #
  #def to_html
  #  @html
  #end

  def initialize_idg(consortium = nil)
    production_centre = nil

    @report = ::NotificationsByGene.new
    @mi_plan_summary = @report.mi_plan_summary(production_centre, consortium, true)

    #puts "#### @mi_plan_summary:"
    #pp @mi_plan_summary

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
    @blurb = "All" if consortium.blank? && production_centre.blank?
    @count = @report.blank? ? 0 : @mi_plan_summary.count
    @pretty_print_statuses = @report.pretty_print_statuses
    @cached = true

    #  @title = 'IDG Gene List Activity'

    @html = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/_report_with_counts3.html.erb")).result(binding) #rescue nil
    @csv = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/notifications_by_gene.csv.erb")).result(binding) #rescue nil
    @consortium = consortium.to_s
  end

  def initialize_default(consortium = nil)
    production_centre = nil

    #puts "#### notifications_by_gene: consortium: #{consortium}"
    #puts "#### notifications_by_gene: production_centre: #{production_centre}"

    @report = ::NotificationsByGene.new
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
    @blurb = "All" if consortium.blank? && production_centre.blank?
    @count = @report.blank? ? 0 : @mi_plan_summary.count
    @pretty_print_statuses = @report.pretty_print_statuses
    @cached = true

    #puts "#### @cached: #{@cached}"

    @html = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/_report_with_counts3.html.erb")).result(binding) #rescue nil
    @csv = ERB.new(File.read("#{Rails.root}/app/views/v2/reports/mi_production/notifications_by_gene.csv.erb")).result(binding) #rescue nil
    @consortium = consortium.to_s

    # puts "#### @html: #{@html}"
  end

  def initialize(consortium = nil, idg = false)
    @idg = idg
    if idg
      initialize_idg consortium
    else
      initialize_default consortium
    end
  end

end
