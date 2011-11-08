# encoding: utf-8

class Reports::MiPlans
  
  # TODO: fix @@funding etc. to be constants

  @@funding = %w[ KOMP2 KOMP2 KOMP2 IMPC IMPC IMPC IMPC IMPC IMPC IMPC IMPC IKMC IKMC IKMC ]
  @@consortia = %w[ BaSH DTCC JAX Helmholtz-GMC MARC MGP MRC Monterotondo NorCOMM2 Phenomin RIKEN-BRC EUCOMM-EUMODIC MGP-KOMP DTCC-KOMP ]

  @@sql = 'select 
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
         
    result = ActiveRecord::Base.connection.select_all( @@sql )

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
  
  def get_double_assigned_mi_plans_str_1
        
    genes, cons_matrix = get_double_assigned_mi_plans_common
  
    string = ',,' + @@funding.join(',') + "\n" + ',,' + @@consortia.join(',') + "\n"
    
    counter = 0
    @@consortia.each do |row1|
      string += @@funding[counter] + ',' + row1 + ','
      thiscounter = 0
      @@consortia.each do |row2|
        if thiscounter <= counter  # skip duplicate rows
          string += 'XXXXX,'
          thiscounter += 1
          next
        end
        genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : {}
        string += genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count.to_s() + ',' : ','
      end
      string += "\n"
      counter += 1
    end

    #string += "\nKOMP2 @@consortia: BaSH; DTCC; JAX\n" +
    #"Other IMPC @@consortia: Helmholtz MARC MGP MRC Monterotondo NorCOMM2 Phenomin Riken BRC\n" +
    #"Legacy production for KOMP and EUCOMM: EUCOMM-EUMODIC; MGP-KOMP; DTCC-KOMP (This is UCD production which is _not_ KOMP2)\n"

    #send_data(
    #  string,
    #  :type     => 'text/csv; charset=utf-8; header=present',
    #  :filename => 'double_assigned1.csv'
    #)
    
    return string
    
  end
  
  def get_double_assigned_mi_plans_data_1
        
    genes, cons_matrix = get_double_assigned_mi_plans_common

    columns = []
    columns.push('dummy')

    #@@funding.each do |funder|
    #  @@consortia.each do |consortium|
    #    columns.push(funder + '/' + consortium)
    #  end    
    #end    

    for i in (0..@@funding.size-1)
      columns.push(@@funding[i] + '/' + @@consortia[i])
    end    

    @report = Table( columns )

    #@report << {
    #  'Marker Symbol'     => gene.marker_symbol,
    #  'MGI Accession ID'  => gene.mgi_accession_id,
    #  '# IKMC Projects'   => gene.ikmc_projects_count,
    #  '# Clones'          => gene.pretty_print_types_of_cells_available.gsub('<br/>',' '),
    #  'Non-Assigned MIs'  => non_assigned_mis[gene.marker_symbol] ? non_assigned_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
    #  'Assigned MIs'      => assigned_mis[gene.marker_symbol] ? assigned_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
    #  'Aborted MIs'       => aborted_mis[gene.marker_symbol] ? aborted_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
    #  'MIs in Progress'   => mis_in_progress[gene.marker_symbol] ? mis_in_progress[gene.marker_symbol].gsub('<br/>',' ') : nil,
    #  'GLT Mice'          => glt_mice[gene.marker_symbol] ? glt_mice[gene.marker_symbol].gsub('<br/>',' ') : nil
    #}
    
    thismatrix = []
      
    rows = 0
    @@consortia.each do |row1|
      cols = 0
      thismatrix[rows] ||= []
      @@consortia.each do |row2|
        if cols <= rows  # skip duplicate rows
          thismatrix[rows][cols] = 0
          cols += 1
          next
        end
        genes_in_overlap = cons_matrix[row1] && cons_matrix[row1][row2] ? cons_matrix[row1][row2] : {}
        thismatrix[rows][cols] = genes_in_overlap && genes_in_overlap.count != 0 ? genes_in_overlap.count : 0
        cols += 1
      end
      rows += 1
    end
    
    #for i in (0..rows-1)
    #    array = columns[i] + thismatrix[i]
    #    @report << array
    #end

    #j = 0
    #for i in (0..rows-1)
    #    @report << { 'dummy' => columns[j] } #+ thismatrix[i]
    #    j += 1
    #end

    #for i in (0..columns.size-1)
    #    #array = columns[i] + thismatrix[i]
    #   # @report << { 'dummy' => columns[i+1] }
    #    
    #    for j in (1..columns.size-2)
    #        #@report << { columns[i+1] => thismatrix[i][j] }
    #        puts("LOG: INFO: #{columns[i+1]}")
    #    end
    #    
    #    #@report << array
    #end


    for i in (0..columns.size-2)
        #@report << { columns[i+1] => thismatrix[i][j] }
     #   thismatrix[i].unshift(columns[i])
        #@report << thismatrix[i]
        array = thismatrix[i]
        array.unshift(columns[i+1])
        @report << array
#        puts("LOG: INFO: #{columns[i+1]}")
    end
        

    
    #string += "\nKOMP2 @@consortia: BaSH; DTCC; JAX\n" +
    #"Other IMPC @@consortia: Helmholtz MARC MGP MRC Monterotondo NorCOMM2 Phenomin Riken BRC\n" +
    #"Legacy production for KOMP and EUCOMM: EUCOMM-EUMODIC; MGP-KOMP; DTCC-KOMP (This is UCD production which is _not_ KOMP2)\n"

    #send_data(
    #  string,
    #  :type     => 'text/csv; charset=utf-8; header=present',
    #  :filename => 'double_assigned1.csv'
    #)
    
    return @report
    
  end
  
  def get_double_assigned_mi_plans_str_2

    genes, cons_matrix = get_double_assigned_mi_plans_common

    string = 'Marker Symbol,Consortium,Plan Status,MI Status,Centre,MI Date'
              
    @@consortia.each do |consortium|
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

    #send_data(
    #  string,
    #  :type     => 'text/csv; charset=utf-8; header=present',
    #  :filename => 'double_assigned2.csv'
    #)  

    return string

  end  

#  private :get_double_assigned_mi_plans_common

end