class TraceFile < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :colony
  belongs_to :mutagenesis_factor

  has_attached_file :trace, :storage => :database
  #do_not_validate_attachment_file_type :trace
  validates_attachment_content_type :trace, { content_type: [/application\/octet-stream/, /biosequence\/scf/] }
  attr_accessible :trace
  attr_accessible :is_het, :marker_symbol

  validate :colony, :presence => true
  validate :mutagenesis_factor, :presence => true
  validate :is_het, :presence => true

  validate do |tf|
    # Validate Marker Symbol has been set
    if tf.marker_symbol.blank?
      tf.errors.add :marker_symbol, 'missing! Please indicate which gene was targeted'
    # Validate Marker Symbol can be found in  database
    elsif Gene.find_by_marker_symbol(tf.marker_symbol).blank?
      tf.errors.add :marker_symbol, 'invalid! Please enter a valid Marker Symbol'
    # Ensure Marker Symbol/Gene was targeted by Mi Attempt 
    elsif !tf.colony.blank? && ![tf.colony.mi_attempt.marker_symbol].include?(tf.marker_symbol)
      tf.errors.add :marker_symbol, "not targeted by Mutagenesis Factor! Please select a Marker Symbol from #{tf.colony.mi_attempt.marker_symbol}"
    end
  end

  before_save :set_mutagenesis_factor

### CALLBACK METHODS
  def set_mutagenesis_factor
    # NOTE! Mi Attempts will have multiple mutagenesis Factors use marker symbol to select correct mutagenesis_factor
    mutagenesis_factors = [self.colony.mi_attempt.mutagenesis_factor]
    selected_mf = mutagenesis_factors.select{|mf| mf.marker_symbol == self.marker_symbol}
 
    return if selected_mf.blank?
    selected_mf = selected_mf.first

    if self.mutagenesis_factor_id.blank? || self.mutagenesis_factor_id != selected_mf.id
      self.mutagenesis_factor_id = selected_mf.id
    end
  end
  private :set_mutagenesis_factor

### INSTANCE METHODS
  def marker_symbol=(arg)
    @marker_symbol = arg
  end

  def marker_symbol
    return @marker_symbol unless @marker_symbol.blank?
    return mutagenesis_factor.mi_attempt.marker_symbol unless mutagenesis_factor_id.blank?
    return nil
  end

### CLASS METHODS

end

# == Schema Information
#
# Table name: trace_files
#
#  id                 :integer          not null, primary key
#  is_het             :boolean          default(FALSE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  trace_file_name    :string(255)
#  trace_content_type :string(255)
#  trace_file_size    :integer
#  trace_updated_at   :datetime
#  allele_id          :integer
#
