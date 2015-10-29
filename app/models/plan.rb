# encoding: utf-8

class MiPlan < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute

  FUNDING = {'IMPC' => {
                 'HMGU' => ['Helmholtz GMC'],
                 'ICS' => ['Phenomin', 'Helmholtz GMC'],
                 'Harwell' => ['BaSH', 'MRC'],
                 'UCD' =>['DTCC'],
                 'WTSI' =>['MGP', 'BaSH'],
                 'Monterotondo' =>['Monterotondo'],
                 'BCM' => 'all',
                 'TCP' => 'all',
                 'JAX' => 'all',
                 'RIKEN BRC' => 'all'
                },
            'KOMP' => [
                'BaSH',
                'DTCC',
                'JAX'
               ]
           }

  belongs_to :gene
  belongs_to :consortium
  belongs_to :production_centre, :class_name => 'Centre'

#  belongs_to :es_qc_comment
#  belongs_to :es_cells_received_from, :class_name => 'TargRep::CentrePipeline'

  has_one :es_cell_qc
  has_many :mi_attempts
  has_many :mouse_allele_mods
  has_many :phenotyping_productions

  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name

  delegate :marker_symbol, :to => :gene
  delegate :mgi_accession_id, :to => :gene

  validates :gene, :presence => true

  validate do |plan|
    if production_centre.blank? && consortium.blank?
      plan.errors.add(:base, 'A plan must be assigned to a center, consortia or both')
    end
  end

  validate do |plan|
    other_ids = Plan.where(:gene_id => plan.gene_id,
      :consortium_id => plan.consortium_id,
      :production_centre_id => plan.production_centre_id)
    other_ids -= [plan.id]
    if(other_ids.count != 0)
      plan.errors.add(:gene, 'already has a plan by that consortium/production centre')
    end
  end


  def products
   @products ||= {:mi_attempts => mi_attempts.where("is_active = true"), :phenotype_attempts => phenotype_attempts.reject{|pa| !pa.is_active}}
  end

  def phenotype_attempts
    pas = []
    phenotype_attempt_ids = []
    phenotype_attempt_ids << mouse_allele_mods.map{|mam| mam.phenotype_attempt_id}.reject { |c| c.blank? }
    phenotype_attempt_ids << phenotyping_productions.map{|pp| pp.phenotype_attempt_id}.reject { |c| c.blank? }

    pas = phenotype_attempt_ids.flatten.uniq.reject { |c| c.blank? }.map{ |pa_id| Public::PhenotypeAttempt.find(pa_id)}
    return pas
  end

  def self.readable_name
    return 'plan'
  end

  def self.find_or_create_plan(object, params, &check_plan_exists)
    raise "Did not check to see if plan already exists" if check_plan_exists.nil?

    plans = check_plan_exists.call(object)
    if plans.count == 1
      plan = plans.first
    elsif plans.count == 0
      plan = Plan.new(params)
      plan.force_assignment = true
      if plan.valid?
        plan.save
      else
        raise "Invalid plan. #{plan.errors.messages}"
      end
    else
      raise "Multiple plans returned. Expected 0-1 plan to be returned for the given params: #{params}"
    end
    return plan

  end


  def impc_activity?
    return false if self.production_centre.blank? || self.consortium.blank?

    if !FUNDING['IMPC'][self.production_centre.name].blank? && (FUNDING['IMPC'][self.production_centre.name] == 'all' || FUNDING['IMPC'][self.production_centre.name].include?(self.consortium.name))
      return true
    else
      return false
    end
  end

  def komp_activity?
    return false if self.consortium.blank? || !FUNDING['KOMP'].include?(self.consortium.name)
    return true
  end

  def self.impc_activity_sql_where

    where_array = []
    FUNDING['IMPC'].each do |key, value|
      where_clause = "(centres.name = '#{key}' "
      if value != 'all'
        where_clause += "AND consortia.name IN ('#{value.join("', '")}')"
      end
      where_clause += ") "
      where_array << where_clause
    end
    return where_array.join(" OR ")
  end

  def self.komp_activity_sql_where
    where_array = FUNDING['KOMP']
    return "consortia.name IN ('#{where_array.join("', '")}')"
  end


end


# == Schema Information
#
# Table name: mi_plans
#
#  id                             :integer          not null, primary key
#  gene_id                        :integer          not null
#  consortium_id                  :integer          not null
#  status_id                      :integer          not null
#  priority_id                    :integer
#  production_centre_id           :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  number_of_es_cells_starting_qc :integer
#  number_of_es_cells_passing_qc  :integer
#  sub_project_id                 :integer          not null
#  is_active                      :boolean          default(TRUE), not null
#  is_bespoke_allele              :boolean          default(FALSE), not null
#  is_conditional_allele          :boolean          default(FALSE), not null
#  is_deletion_allele             :boolean          default(FALSE), not null
#  is_cre_knock_in_allele         :boolean          default(FALSE), not null
#  is_cre_bac_allele              :boolean          default(FALSE), not null
#  comment                        :text
#  withdrawn                      :boolean          default(FALSE), not null
#  es_qc_comment_id               :integer
#  phenotype_only                 :boolean          default(FALSE)
#  completion_note                :string(100)
#  recovery                       :boolean
#  conditional_tm1c               :boolean          default(FALSE), not null
#  ignore_available_mice          :boolean          default(FALSE), not null
#  number_of_es_cells_received    :integer
#  es_cells_received_on           :date
#  es_cells_received_from_id      :integer
#  point_mutation                 :boolean          default(FALSE), not null
#  conditional_point_mutation     :boolean          default(FALSE), not null
#  allele_symbol_superscript      :text
#  report_to_public               :boolean          default(TRUE), not null
#  completion_comment             :text
#  mutagenesis_via_crispr_cas9    :boolean          default(FALSE)
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id,sub_project_id,is_bespoke_allele,is_conditional_allele,is_deletion_allele,is_cre_knock_in_allele,is_cre_bac_allele,conditional_tm1c,phenotype_only,mutagenesis_via_crispr_cas9) UNIQUE
#
