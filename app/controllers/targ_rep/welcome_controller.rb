class TargRep::WelcomeController < TargRep::BaseController

  skip_before_filter :authenticate_user!

  def index
    
    # First fetch our counts from the DB - this direct SQL approach 
    # is much faster than going via the model....
    allele_counts = allele_count_by_pipeline
    gene_counts   = gene_count_by_pipeline
    vector_counts = targeting_vector_count_by_pipeline
    escell_counts = escell_count_by_pipeline
    
    @pipeline_counts = {}
    @total_counts    = {
      :pipelines => 0,
      :alleles   => 0,
      :genes     => 0,
      :vectors   => 0,
      :es_cells  => 0
    }

    TargRep::Pipeline.all.each do |pipeline|
      @pipeline_counts[pipeline.name] = {
        :alleles  => allele_counts[pipeline.id] ? allele_counts[pipeline.id] : 0,
        :genes    => gene_counts[pipeline.id]   ? gene_counts[pipeline.id]   : 0,
        :vectors  => vector_counts[pipeline.id] ? vector_counts[pipeline.id] : 0,
        :es_cells => escell_counts[pipeline.id] ? escell_counts[pipeline.id] : 0
      }
      @total_counts[:pipelines] += 1
      @total_counts[:alleles]   += @pipeline_counts[pipeline.name][:alleles]
      @total_counts[:genes]     += @pipeline_counts[pipeline.name][:genes]
      @total_counts[:vectors]   += @pipeline_counts[pipeline.name][:vectors]
      @total_counts[:es_cells]  += @pipeline_counts[pipeline.name][:es_cells]
    end
  end
   
  private
  
  def allele_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id as id,
        count(allele_id) as count
      from (
        select distinct ( targ_rep_alleles.id ) as allele_id, targ_rep_targeting_vectors.pipeline_id
        from targ_rep_alleles
        join targ_rep_targeting_vectors on targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
        union
        select distinct ( targ_rep_alleles.id ) as allele_id, targ_rep_es_cells.pipeline_id
        from targ_rep_alleles
        join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.pipeline_id
      ) tmp
      group by id
    SQL

    Rails.logger.debug 'Allele count by Pipeline'
    run_count_sql(sql)
  end
  
  def gene_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id as id,
        count(gene_id) as count
      from (
        select distinct ( targ_rep_alleles.gene_id ) as gene_id, targ_rep_targeting_vectors.pipeline_id
        from targ_rep_alleles
        join targ_rep_targeting_vectors on targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
        union
        select distinct ( targ_rep_alleles.gene_id ) as gene_id, targ_rep_es_cells.pipeline_id
        from targ_rep_alleles
        join targ_rep_es_cells on targ_rep_alleles.id = targ_rep_es_cells.pipeline_id
      ) tmp
      group by id
    SQL

    Rails.logger.debug 'Gene count by Pipeline'
    run_count_sql(sql)
  end
  
  def targeting_vector_count_by_pipeline
    sql = <<-SQL
      select
        targ_rep_targeting_vectors.pipeline_id id,
        count(targ_rep_targeting_vectors.id) count
      from
        targ_rep_targeting_vectors
      group by pipeline_id
    SQL

    Rails.logger.debug 'Targeting Vector count by Pipeline'
    run_count_sql(sql)
  end
  
  def escell_count_by_pipeline
    sql = <<-SQL
      select
        targ_rep_es_cells.pipeline_id id,
        count(targ_rep_es_cells.id) count
      from
        targ_rep_es_cells
      group by pipeline_id
    SQL

    Rails.logger.debug 'Es Cell count by Pipeline'
    run_count_sql(sql)
  end
  
  def run_count_sql(sql)
    counts  = {}
    results = ActiveRecord::Base.connection.execute(sql)

    results.each do |res|
      res = res.values
      counts[ res[0].to_i ] = res[1].to_i
    end

    puts counts
    return counts
  end
  
end