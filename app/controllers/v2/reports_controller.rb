class V2::ReportsController < ApplicationController

  helper :reports

  before_filter :authenticate_user!, :except => [:komp_project, :idcc_master_genelist, :mgi_modification_allele_report, :mgi_es_cell_allele_report, :mgi_mixed_allele_report, :mgi_crispr_allele_report, :mp2_load_phenotyping_colonies_report, :mp2_load_gene_interest_report, :mp2_load_gene_contact_report, :mp2_load_gene_contact_sent_report, :emma_distribution_report]

  before_filter do
    if params[:format] == 'csv'
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Type"] = "text/csv"
      response.headers["Content-Disposition"] = "attachment;filename=#{action_name}-#{Date.today.to_s(:db)}.csv"
    end
  end

  before_filter do
    if params[:format] == 'tab'
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Type"] = "text/tab"
      response.headers["Content-Disposition"] = "attachment;filename=#{action_name}-#{Date.today.to_s(:db)}.tab"
    end
  end

  before_filter do
    if params[:format] == 'tsv'
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Type"] = "text/tsv"
      response.headers["Content-Disposition"] = "attachment;filename=#{action_name}-#{Date.today.to_s(:db)}.tsv"
    end
  end

  def index
    redirect_to reports_path
  end

  def planned_microinjection_summary_and_conflicts
    @report = MicroInjectionSummaryAndConflictsReport.new
    @consortia_by_priority = @report.consortia_by_priority
    @consortia_by_status = @report.consortia_by_status
    @consortia_totals = @report.consortia_totals
    @priority_totals = @report.priority_totals
    @status_totals = @report.status_totals
    @consortia = @report.consortia

    @statuses = @report.class.statuses
    @priorities = @report.class.priorities
  end

  def qc_grid_summary
    @report = QcGridReport::Summary.new
    @centre_by_consortia = @report.centre_by_consortia
    @score_averages = @report.generate_report
  end

  def qc_grid
    @report = QcGridReport.new

    @report.conditions = params
    @report.run

    @report_rows = @report.report_rows
  end

  def komp_project
    @report= IkmcProjectFeed.new
    @komp_project = @report.komp_project
  end

  def idcc_master_genelist
    @report= IkmcProjectFeed.new
    @idcc_master_genelist = @report.idcc_master_genelist.to_a
    respond_to do |format|
      format.tab
    end
  end

  def mp2_load_phenotyping_colonies_report
    @report = Mp2Load::PhenotypingColoniesReport.new
    @phenotyping_colonies = @report.phenotyping_colonies
    respond_to do |format|
      format.tsv {render :mp2_load_phenotyping_colonies_report}
    end
  end

  def mp2_load_gene_interest_report
    @report = Mp2Load::GeneInterestReport.new
    @gene_statues = @report.gene_statues
    respond_to do |format|
      format.tsv {render :mp2_load_gene_interest_report}
    end
  end

  def mp2_load_gene_contact_report
    @report = Mp2Load::NotificationReport.new
    @notifications = @report.notifications
    respond_to do |format|
      format.tsv {render :mp2_load_notification_report}
    end
  end

  def mp2_load_gene_contact_sent_report
    @report = Mp2Load::LegacyEmailsSentReport.new
    @legacy_emails_sent = @report.legacy_emails_sent
    respond_to do |format|
      format.tsv {render :mp2_load_legacy_email_sent_report}
    end
  end

  def emma_distribution_report
    @report = Emma::DistributedReport.new
    @distribution_data = @report.distribution_data
    respond_to do |format|
      format.tsv {render :emma_distribution_data_report}
    end
  end

  def mgi_modification_allele_report
    @report = MgiAlleleLoad::MouseAlleleModReport.new
    @mgi_allele = @report.phenotype_attempt_mgi_allele
    respond_to do |format|
      format.tsv {render :mgi_allele_report}
    end
  end

  def mgi_es_cell_allele_report
    @report = MgiAlleleLoad::EsCellReport.new
    @mgi_allele = @report.es_cell_mgi_allele
    respond_to do |format|
      format.tsv {render :mgi_allele_report}
    end
  end

  def mgi_mixed_allele_report
    @report = MgiAlleleLoad::MixedCloneAlleleReport.new
    @mgi_allele = @report.mixed_clone_mgi_allele
    respond_to do |format|
      format.tsv {render :mgi_allele_report}
    end
  end

  def mgi_crispr_allele_report
    @report = MgiAlleleLoad::CrisprAlleleReport.new
    @mgi_allele = @report.crispr_mgi_allele
    respond_to do |format|
      format.tsv {render :mgi_allele_report}
    end
  end



  def mi_attempt_repository_reconciled_summary
    report = MiAttemptRepositoryReconciledSummaryReport.new
    @mi_reconciled_komp_summary_list  = report.mi_reconciled_komp_summary_list
    @mi_reconciled_emma_summary_list  = report.mi_reconciled_emma_summary_list
    @mi_reconciled_mmrrc_summary_list = report.mi_reconciled_mmrrc_summary_list
  end

  def komp_mi_unreconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = MiAttemptKompUnreconciledListReport.new(@consortium, @prod_centre)
    @komp_unreconciled_list = report.komp_unreconciled_list
  end

  def komp_mi_reconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = MiAttemptKompReconciledListReport.new(@consortium, @prod_centre)
    @komp_reconciled_list = report.komp_reconciled_list
  end

  def emma_mi_unreconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = MiAttemptEmmaUnreconciledListReport.new(@consortium, @prod_centre)
    @emma_unreconciled_list = report.emma_unreconciled_list
  end

  def emma_mi_reconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = MiAttemptEmmaReconciledListReport.new(@consortium, @prod_centre)
    @emma_reconciled_list = report.emma_reconciled_list
  end

  def mmrrc_mi_unreconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = MiAttemptMmrrcUnreconciledListReport.new(@consortium, @prod_centre)
    @mmrrc_unreconciled_list = report.mmrrc_unreconciled_list
  end

  def mmrrc_mi_reconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = MiAttemptMmrrcReconciledListReport.new(@consortium, @prod_centre)
    @mmrrc_reconciled_list = report.mmrrc_reconciled_list
  end

  def phenotype_attempt_repository_reconciled_summary
    report = PhenotypeAttemptRepositoryReconciledSummaryReport.new
    @phenotype_reconciled_komp_summary_list  = report.phenotype_reconciled_komp_summary_list
    @phenotype_reconciled_emma_summary_list  = report.phenotype_reconciled_emma_summary_list
    @phenotype_reconciled_mmrrc_summary_list = report.phenotype_reconciled_mmrrc_summary_list
  end

  def komp_phenotype_unreconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = PhenotypeAttemptKompUnreconciledListReport.new(@consortium, @prod_centre)
    @komp_unreconciled_list = report.komp_unreconciled_list
  end

  def komp_phenotype_reconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = PhenotypeAttemptKompReconciledListReport.new(@consortium, @prod_centre)
    @komp_reconciled_list = report.komp_reconciled_list
  end

  def emma_phenotype_unreconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = PhenotypeAttemptEmmaUnreconciledListReport.new(@consortium, @prod_centre)
    @emma_unreconciled_list = report.emma_unreconciled_list
  end

  def emma_phenotype_reconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = PhenotypeAttemptEmmaReconciledListReport.new(@consortium, @prod_centre)
    @emma_reconciled_list = report.emma_reconciled_list
  end


  def mmrrc_phenotype_unreconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = PhenotypeAttemptMmrrcUnreconciledListReport.new(@consortium, @prod_centre)
    @mmrrc_unreconciled_list = report.mmrrc_unreconciled_list
  end

  def mmrrc_phenotype_reconciled_list
    @consortium = params[:consortium]
    if @consortium.blank?
      flash[:alert] = "Missing Consortium Name"
    end

    @prod_centre = params[:prod_centre]
    if @prod_centre.blank?
      flash[:alert] = "Missing Production Centre"
    end

    report = PhenotypeAttemptMmrrcReconciledListReport.new(@consortium, @prod_centre)
    @mmrrc_reconciled_list = report.mmrrc_reconciled_list
  end















end