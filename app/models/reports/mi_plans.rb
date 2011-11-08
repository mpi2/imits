# encoding: utf-8

class Reports::MiPlans
  
  # TODO: fix FUNDING etc. to be constants

  FUNDING = %w[ KOMP2 KOMP2 KOMP2 IMPC IMPC IMPC IMPC IMPC IMPC IMPC IMPC IKMC IKMC IKMC ]
  CONSORTIA = %w[ BaSH DTCC JAX Helmholtz-GMC MARC MGP MRC Monterotondo NorCOMM2 Phenomin RIKEN-BRC EUCOMM-EUMODIC MGP-KOMP DTCC-KOMP ]

  SQL = 'select 
    marker_symbol as marker_symbol,
    mi_plan_statuses.name as mi_plan_statuses_name, 
    centres.name as centres_name,
    consortia.name as consortia_name,
    mi_attempts.mi_date as mi_attempts_mi_date,
    es_cells.name as es_cells_name,
    mi_attempts.is_active as mi_attempts_is_active, 
    mi_attempts.is_suitable_for_emma,
    mi_attempt_statuses.description as mi_attempt_statuses_description
    from mi_plans join mi_plan_statuses on mi_plans.mi_plan_status_id = mi_plan_statuses.id
    left outer join mi_attempts on mi_plans.id = mi_attempts.mi_plan_id
    left outer join mi_attempt_statuses on mi_attempts.mi_attempt_status_id = mi_attempt_statuses.id
    left outer join es_cells on mi_attempts.es_cell_id = es_cells.id 
    join consortia on mi_plans.consortium_id = consortia.id
    join centres on mi_plans.production_centre_id = centres.id
    join genes on mi_plans.gene_id = genes.id
    where mi_plans.gene_id in (    
      select gene_id
      from mi_plans
      where mi_plan_status_id = 1
      group by gene_id
      having count(*) > 1    
  ) and mi_plan_status_id =1 order by marker_symbol;'

  # TODO: needs to be modified for ES QC states

  def get_double_assigned_mi_plans_common
         
    result = ActiveRecord::Base.connection.select_all( SQL )

    genes = {}  
    result.each do |row|
      genes[row['marker_symbol']] ||= {}
      genes[row['marker_symbol']][row['consortia_name']] =
        [
          row['marker_symbol'],
          row['consortia_name'],
          row['mi_plan_statuses_name'],
          row['mi_attempt_statuses_description'],
          row['centres_name'],
          row['mi_attempts_mi_date'],
          row['mi_attempts_is_active'],
          row['is_suitable_for_emma']
        ]
    end
     
    cons_matrix = {}    
    genes.each_pair do |k1, v1|
      genes[k1].each_pair do |k2, v2|
        genes[k1].each_pair do |k3, v3|
          cons_matrix[k2] ||= {}
          cons_matrix[k2][k3] ||= {}
          cons_matrix[k2][k3][k1] = 1 if k2 != k3;
        end
      end
    end
    
    return genes, cons_matrix
  
  end
  
  #def get_double_assigned_mi_plans_str_1
  #      
  #  genes, cons_matrix = get_double_assigned_mi_plans_common
  #
  #  string = ',,' + FUNDING.join(',') + "\n" + ',,' + CONSORTIA.join(',') + "\n"
  #  
  #  counter = 0
  #  CONSORTIA.each do |row1|
  #    string += FUNDING[counter] + ',' + row1 + ','
  #    thiscounter = 0
  #    CONSORTIA.each do |row2|
  #      if thiscounter <= counter  # skip duplicate rows
  #        string += 'XXXXX,'
  #        thiscounter += 1
  #        next
  #      end
  #      genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : {}
  #      string += genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count.to_s() + ',' : ','
  #    end
  #    string += "\n"
  #    counter += 1
  #  end
  #
  #  return string
  #  
  #end
  
  def get_double_assigned_mi_plans_data_1
        
    genes, cons_matrix = get_double_assigned_mi_plans_common

    columns = []
    columns.push('')

    for i in (0..FUNDING.size-1)
      columns.push(FUNDING[i] + '/' + CONSORTIA[i])
    end    

    report = Table( columns )
    
    matrix = []
      
    rows = 0
    CONSORTIA.each do |row1|
      cols = 0
      matrix[rows] ||= []
      CONSORTIA.each do |row2|
        if cols <= rows  # skip duplicate rows
          matrix[rows][cols] = ''
          cols += 1
          next
        end
        genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : {}
        matrix[rows][cols] = genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count : ''
        cols += 1
      end
      rows += 1
    end
    
    for i in (0..columns.size-2)
        array = matrix[i]
        array.unshift(columns[i+1])
        report << array
    end
    
    return report
    
  end
  
  def get_double_assigned_mi_plans_str_2

    genes, cons_matrix = get_double_assigned_mi_plans_common

    string = 'Marker Symbol,Consortium,Plan Status,MI Status,Centre,MI Date'
              
    CONSORTIA.each do |consortium|
      string += "\n\nDOUBLE-ASSIGNMENTS FOR consortium: #{consortium}\n\n";
      genes.each_pair do |marker, value|
        consortia_for_gene = value.keys
        array = consortia_for_gene.grep(/^#{consortium}$/)
        if array && array.size > 0
          keys = value.except('mi_attempts_is_active', 'is_suitable_for_emma').keys
          keys.each do |found_consortium|
            mi_array = genes[marker][found_consortium];
            mi_status = mi_array[3]
            next if mi_status == 'Micro-injection aborted'
            string += mi_array[0..-3].join(',') + "\n"  # drop final two columns
          end
        end        
      end
      string += "\n"      
    end

    return string

  end  

end