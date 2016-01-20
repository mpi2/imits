class Public::Plan < ::Plan

  include ::Public::Serializable
  FULL_ACCESS_ATTRIBUTES = %w{
    marker_symbol
    consortium_name
    production_centre_name
}

  READABLE_ATTRIBUTES = %w{
    id
    es_cell_qc_intent
    es_cell_mi_attempt_intent
    crispr_mi_attempt_intent
    mouse_allele_modification_intent
    phenotyping_intent
    mi_attempts_count
    mouse_allele_modification_count
    phenotyping_count
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)


  def es_cell_qc_intent
    if qc_es_cell_intention.blank?
      return false
    else
      return true
    end
  end

  def es_cell_mi_attempt_intent
    if micro_injected_es_cell_intention.blank?
      return false
    else
      return true
    end
  end
  
  def crispr_mi_attempt_intent
    if micro_injected_crispr_intention.blank?
      return false
    else
      return true
    end
  end

  def mouse_allele_modification_intent
    if modify_mice_allele_intention.blank?
      return false
    else
      return true
    end
  end

  def phenotyping_intent
    if phenotype_mice_intention.blank?
      return false
    else
      return true
    end
  end
  
  def mi_attempts_count
    1
  end

  def mouse_allele_modification_count
    1
  end
  
  def phenotyping_count
    1
  end

  def self.translations
    return {
      'marker_symbol' => 'gene_marker_symbol'
    }
  end
end

