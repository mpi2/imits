class SolrUpdate::Enqueuer
  def mi_attempt_updated(mi)
    return if mi.gene.mgi_accession_id.nil?

    reference = {'type' => 'mi_attempt', 'id' => mi.id}

    if mi.has_status? :gtc and ! mi.has_status? :abt and mi.allele_id > 0
      SolrUpdate::Queue.enqueue_for_update(reference)
    else
      SolrUpdate::Queue.enqueue_for_delete(reference)
    end

    mi_plan_updated(mi.mi_plan)

    mi.phenotype_attempts.reload.each do |pa|
      self.phenotype_attempt_updated(pa)
      self.mi_plan_updated(pa.mi_plan) if pa.mi_plan
    end

  end

  def mi_attempt_destroyed(mi)
    SolrUpdate::Queue.enqueue_for_delete({'type' => 'mi_attempt', 'id' => mi.id})

    mi_plan_updated(mi.mi_plan)
  end

  def phenotype_attempt_updated(pa)
    reference = {'type' => 'phenotype_attempt', 'id' => pa.id}

    if pa.has_status? :cec and ! pa.has_status? :abt and pa.allele_id > 0
      SolrUpdate::Queue.enqueue_for_update(reference)
    else
      SolrUpdate::Queue.enqueue_for_delete(reference)
    end

    mi_plan_updated(pa.mi_plan) if pa.mi_plan
  end

  def phenotype_attempt_destroyed(pa)
    SolrUpdate::Queue.enqueue_for_delete({'type' => 'phenotype_attempt', 'id' => pa.id})

    mi_plan_updated(pa.mi_plan) if pa.mi_plan
  end

  def any_with_mi_attempts_updated(object)
    if object.changes.present?
      object.mi_attempts.reload.each {|mi| mi_attempt_updated(mi); mi_plan_updated(mi.mi_plan) }
    end
  end

  def update_mi_or_phenotype_attempt(object)
    if object.respond_to? 'phenotype_attempt'
      phenotype_attempt_updated(object.phenotype_attempt)
    else
      mi_attempt_updated(object.mi_attempt)
    end

    mi_plan_updated(object) if object.kind_of? MiPlan
  end

  def allele_updated(allele)
    begin
      SolrUpdate::Queue.enqueue_for_update({'type' => 'allele', 'id' => allele.id})
    rescue SolrUpdate::LookupError
      SolrUpdate::Queue.enqueue_for_delete({'type' => 'allele', 'id' => allele.id})
    end
  end

  def allele_destroyed(allele)
    SolrUpdate::Queue.enqueue_for_delete({'type' => 'allele', 'id' => allele.id})
  end

  def es_cell_updated(es_cell)
    allele_updated(es_cell.allele)
  end

  def es_cell_destroyed(es_cell)
    allele_updated(es_cell.allele)
  end

  def mi_plan_updated(plan)
    begin
      SolrUpdate::Queue.enqueue_for_update(plan.gene)
    rescue SolrUpdate::LookupError
      SolrUpdate::Queue.enqueue_for_delete(plan.gene)
    end
  end

  def mi_plan_destroyed(plan)
    SolrUpdate::Queue.enqueue_for_delete(plan.gene)
  end

  def gene_updated(gene)
    begin
      return if gene.mi_plans.size == 0
      SolrUpdate::Queue.enqueue_for_update(gene)
    rescue SolrUpdate::LookupError
      SolrUpdate::Queue.enqueue_for_delete(gene)
    end
  end

  def gene_destroyed(gene)
    SolrUpdate::Queue.enqueue_for_delete(gene)
  end

end
