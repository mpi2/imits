module Reports::ImpcGeneList
  @status_rename_map = {
    'Interest' => 'Assigned',
    'Conflict' => 'Assigned',
    'Inspect - GLT Mouse' => 'Assigned',
    'Inspect - MI Attempt' => 'Assigned',
    'Inspect - Conflict' => 'Assigned',
    'Assigned' => 'Assigned',
    'Assigned - ES Cell QC In Progress' => 'Assigned',
    'Assigned - ES Cell QC Complete' => 'Assigned',
    'Aborted - ES Cell QC Failed' => 'Assigned',
    'Inactive' => 'Project Withdrawn',
    'Withdrawn' => 'Project Withdrawn',
    # mi attempts
    'Micro-injection in progress' => 'Mouse Production in Progress', 
    'Chimeras obtained' => 'Mouse Production in Progress', 
    'Micro-injection aborted' => 'Mouse Production in Progress', 
    'Chimeras obtained' => 'Mouse Production in Progress',
    'Genotype confirmed' => 'Genotype Confirmed Mice',
    # phenotype attempts
    "Phenotype Attempt Aborted" => "Genotype Confirmed Mice",
    "Phenotype Attempt Registered" => 'Genotype Confirmed Mice',
    "Rederivation Started" => 'Genotype Confirmed Mice',
    "Rederivation Complete"  => 'Genotype Confirmed Mice',
    "Cre Excision Started" => 'Genotype Confirmed Mice',
    "Cre Excision Complete"  => 'Genotype Confirmed Mice',
    "Phenotyping Started"  => 'Genotype Confirmed Mice',
    "Phenotyping Complete"  => 'Phenotyping Complete'
  }

  @status_order = {
    'Project Withdrawn' => 1,
    'Assigned' => 2,
    'Mouse Production in Progress' => 3,
    'Genotype Confirmed Mice' => 4,
  }
  
  def self.generate(format)
    raise "only csv format currently supported" unless (format == :csv)
    intermediate = ReportCache.where({:name=>'mi_production_intermediate',:format=>'csv'}).first
    csv_data = CSV.parse(intermediate.data)
    headers = csv_data[0]
    cache_by_gene = cache_data_by_gene(headers, csv_data, @status_rename_map, @status_order)
    output = create_output(headers, cache_by_gene)
    output_string = ""
    output.each do |output_line|
      output_string = output_string + output_line.join(",") + "\n"
    end
    return output_string
  end

  def self.create_output(format, cache_by_gene)
    output = []
    gene_names = cache_by_gene.keys
    gene_names.sort!
    output << ['Gene','MGI Accession ID','Overall Status','IKMC Project ID']
    
    gene_names.each do |key|
      best_project = nil
      if(cache_by_gene[key].length == 1)
        best_project = cache_by_gene[key][0]
      else
        projects = cache_by_gene[key]
        projects.sort! {|a,b| b['sort_order'] <=> a['sort_order']}
        best_project = projects[0]
      end
      output_line = [
        best_project['Gene'],
        best_project['MGI Accession ID'],
        best_project['Overall Status'],
        best_project['IKMC Project ID']
      ]
      output << output_line
    end
    return output
  end
  
  def self.cache_data_by_gene(headers, csv_data, status_rename_map, status_order)
    cache_by_gene = {}
    first_line = true;
    # Parse each line in intermediate report. Cache by gene and rename overall statuses
    csv_data.each do |line|
      if (first_line)
        first_line = false
        next
      end
      x = 0
      report_fields = {}
      while x < headers.length
        if headers[x] == 'Overall Status'
          new_status = status_rename_map[line[x]]
          sort_order = status_order[new_status] 
          if new_status.nil?
            raise "cant find status rename for status #{line[x]}"
          end
          report_fields[headers[x]] =  new_status
          report_fields['sort_order'] =  sort_order
        else
          report_fields[headers[x]] =  line[x]
        end
            
        x = x+1
      end
      
      if(cache_by_gene[report_fields['Gene']].nil?)
        cache_by_gene[report_fields['Gene']] = []
      end
          
      cache_by_gene[report_fields['Gene']] << report_fields
        
    end
    return cache_by_gene
  end
end
