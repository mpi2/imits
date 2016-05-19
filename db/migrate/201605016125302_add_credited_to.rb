class AddCreditedTo < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :mrna_nuclease, :string
    add_column :mi_attempts, :mrna_nuclease_concentration, :float
    add_column :mi_attempts, :protein_nuclease, :string
    add_column :mi_attempts, :protein_nuclease_concentration, :float
    add_column :mi_attempts, :delivery_method, :string

    create_table :mutagenesis_factor_vectors do |t|
      t.integer :mutagenesis_factor_id, :null => false
      t.integer :vector_id
      t.float   :concentration
      t.string  :preparation
    end

    create_table :reagent_names do |t|
      t.string :name, :null => false
      t.text :description
    end

    create_table :reagents do |t|
      t.integer :mi_attempt_id, :null => false
      t.string  :reagent_id, :null => false
      t.float   :concentration
    end

    add_column :targ_rep_crisprs, :truncated_guide, :boolean, :default => false

    add_column :mutagenesis_factors, :individually_set_grna_concentrations, :boolean, :null => false, :default => false
    add_column :mutagenesis_factors, :guides_generated_in_plasmid, :boolean, :null => false, :default => false

    add_column :mutagenesis_factors, :grna_concentration, :float
    add_column :targ_rep_crisprs, :grna_concentration, :float

    sql = <<-EOF
      UPDATE mi_attempts SET (mrna_nuclease, protein_nuclease) = (
        CASE WHEN mutagenesis_factors.nuclease = 'CAS9 mRNA' THEN 'CAS9'
             WHEN mutagenesis_factors.nuclease = 'D10A mRNA' THEN 'D10A'
        ELSE '' END,
        CASE WHEN mutagenesis_factors.nuclease = 'CAS9 Protein' THEN 'CAS9'
             WHEN mutagenesis_factors.nuclease = 'D10A Protein' THEN 'D10A'
        ELSE '' END
        )
      FROM mutagenesis_factors
      WHERE mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id;

      INSERT INTO mutagenesis_factor_vectors(mutagenesis_factor_id, vector_id)
      SELECT mutagenesis_factors.id, mutagenesis_factors.vector_id
      FROM mutagenesis_factors
      WHERE mutagenesis_factors.vector_id IS NOT NULL;

      INSERT INTO reagent_names(name, description) VALUES
      ('Ligase IV', 'NHEJ Inhibitor'),
      ('Xrcc5', 'NHEJ Inhibitor')
    EOF

    ActiveRecord::Base.connection.execute(sql)

    apn = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'APN'")
    apn.each do |row|
      id = row['id']
      comment = row['comments']
      grna_concentration = nil
      nuclease_concentration = nil
      md = /Cas9 mRNA (\d+) ng\/ul\s+sgRNAs (\d+) ng\/ul/.match(comment) 
      grna_concentration = md[2] unless md.blank?
      nuclease_concentration = md[1] unless md.blank?

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration})
    end


    bcm = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'BCM'")
    bcm.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil
      delivery_method = nil
      plasmid_preparation = nil
      inhibitor = nil

      md = /Cas9[a-zA-Z \(\):]+([\d.]+)[ ]*ng\/ul/.match(comment)
      nuclease_concentration = md[1] unless md.blank?
      md = /gRNA[\d]*[: at]*([\d.]+)[ ]*ng\/ul/.match(comment)
      grna_concentration = md[1] unless md.blank?
      md = /donor[s]*[ atDNA]+([\d.]+)[ ]*ng\/ul/.match(comment)
      vector_concentration = md[1] unless md.blank?
      md = /[Oo]ligo[ atdonrsDNA]+([\d.]+)[ ]*ng\/ul/.match(comment)
      unless md.blank?
        vector_concentration = md[1] unless  !vector_concentration.blank?
        plasmid_preparation = 'Oligo'
      end
      md = /[lL]igase/.match(comment)
      inhibitor = 'Ligase IV' unless md.blank?
      delivery_method = 'Cytoplasmic Injection' if comment =~ /Cytoplasmic/
      delivery_method = 'Pronuclear Injection' if comment =~ /Nuclear/

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method, :plasmid_preparation => plasmid_preparation, :inhibitor => inhibitor})
    end

    harwell = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'Harwell'")
    harwell.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil
      delivery_method = nil
      plasmid_preparation = nil

      md = /Cas9[ a-zA-Z10]*RNA[= ]*([\d.]+)[ ]*ng/.match(comment)
      nuclease_concentration = md[1] unless md.blank?
      md = /gRNA[s]*[= ]*([\d.]+)[ ]*ng/.match(comment)
      grna_concentration = md[1] unless md.blank?
      md = /Single stranded donor oligo[ =]*([\d.]+)[ ]*ng/.match(comment)
      unless md.blank?
        vector_concentration = md[1]
        plasmid_preparation = 'Oligo'
      end
      md = /ssODN templates[ =]*([\d.]+)[ ]*ng/.match(comment)
      unless md.blank?
        vector_concentration = md[1] unless !vector_concentration.blank?
        plasmid_preparation = 'Oligo'
      end
      vector_concentration = md[1] unless md.blank? || !vector_concentration.blank?
      md = /donor template[s]*[ =]*([\d.]+)[ ]*ng/.match(comment)
      vector_concentration = md[1] unless md.blank? || !vector_concentration.blank?
      md = /donor plasmid template[ =]*([\d.]+)[ ]*ng/.match(comment)
      vector_concentration = md[1] unless md.blank? || !vector_concentration.blank?
      delivery_method = 'Pronuclear Injection' if comment =~ /[Pp]ronuclear/

      plasmid_preparation = 'Linearized' if comment =~ /[lL]inearized/
      plasmid_preparation = 'Supercoiled' if comment =~ /[sS]upercoiled/

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method, :plasmid_preparation => plasmid_preparation})
    end

    jax = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'JAX'")
    jax.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil
      delivery_method = nil
      truncated = nil
      single_plasmid_delivery = nil
      plasmid_preparation = nil
      inhibitor = nil

      md = /Cas9[a-zA-Z :_]*([\d.]+)[ ]*ng/.match(comment)
      nuclease_concentration = md[1] unless md.blank?
      md = /gRNA[\d]*[:at ]*([\d.]+)[ ]*ng/.match(comment)
      grna_concentration = md[1] unless md.blank?
      md = /guide[s]*[: ]*([\d.]+)[ ]*ng/.match(comment)
      grna_concentration = md[1] unless !grna_concentration.blank? || md.blank?
      md = /Donor[: ]*([\d.]+)[ ]*ng/.match(comment)
      vector_concentration = md[1] unless md.blank?
      md = /[tT]ru-gRNA/.match(comment)
      truncated = true unless md.blank?
      md = /[pP]lasmid(?: microinjection):/.match(comment)
      single_plasmid_delivery = true unless md.blank?
      md = /[Xx]rcc5/.match(comment)
      inhibitor = 'Xrcc5' unless md.blank?
      delivery_method = 'Cytoplasmic Injection' if comment =~ /Cytoplasmic/
      delivery_method = 'Pronuclear Injection' if comment =~ /Pronuclear/

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method, :truncated => truncated, :single_plasmid_delivery => single_plasmid_delivery, :inhibitor => inhibitor})
    end

    riken = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'RIKEN BRC'")
    riken.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil
      delivery_method = nil
      plasmid_preparation = nil

      md = /Cas9[a-zA-Z ]+([\d.]+)[ ]*ng/.match(comment)
      nuclease_concentration = md[1] unless md.blank?
      md = /gRNAs[ ]*([\d.]+)[ ]*ng/.match(comment)
      grna_concentration = md[1] unless md.blank?
      md = /ssODN[s]*[ ]*([\d.]+)[ ]*ng/.match(comment)
      unless md.blank?
        vector_concentration = md[1] 
        plasmid_preparation = 'Oligo'
      end
      delivery_method = 'Electroporation' if comment =~ /electroporation/

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method, :plasmid_preparation => plasmid_preparation})
    end

    tcp = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'TCP'")
    tcp.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil
      plasmid_preparation = nil

      md = /([\d.]+)[ ]*ng\/ul [Cas9D10A]/.match(comment)
      nuclease_concentration = md[1] unless md.blank?
      md = /Cas9[ ]+([\d.]+)[ ]*ng\/u[lL]/.match(comment)
      nuclease_concentration = md[1] unless !nuclease_concentration.blank? || md.blank?
      md = /([\d.]+)[ ]*ng\/ul[ \w]*gRNA/.match(comment)
      grna_concentration = md[1] unless md.blank?
      md = /([\d.]+)[ ]*ng\/ul ssoligo/.match(comment)
      unless md.blank?
        vector_concentration = md[1]
        plasmid_preparation = 'Oligo'
      end
      
      delivery_method = 'Pronuclear Injection'

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method, :plasmid_preparation => plasmid_preparation})
    end

    ucd = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'UCD'")
    ucd.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil

      md = /(?:[\d]+(?:\.[\d]+)*[\/]*)+/.match(comment)
      if !md.blank?
        contrs = md[0].split('/')
        nuclease_concentration = contrs[0] unless contrs.blank? || contrs[0].blank?
        grna_concentration = contrs[1] unless contrs.blank? || contrs[1].blank?
        vector_index = 2
        if !contrs.blank? && contrs.length > 3
          vector_index = contrs.length - 2
        end
        vector_concentration = contrs[vector_index] unless contrs.blank? || contrs[vector_index].blank?
      end
      delivery_method = 'Pronuclear Injection'

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method})
    end

    wtsi = ActiveRecord::Base.connection.execute("SELECT mi_attempts.id, mi_attempts.comments FROM mi_attempts JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id JOIN centres ON centres.id = mi_plans.production_centre_id WHERE mi_attempts.mutagenesis_factor_id IS NOT NULL AND centres.name = 'WTSI'")
    wtsi.each do |row|
      id = row['id']
      comment = row['comments']
      nuclease_concentration = nil
      grna_concentration = nil
      vector_concentration = nil
      delivery_method = nil
      plasmid_preparation = nil

      md = /Cas[ ]*9[ a-zA-Z]*([\d.]+)ng/.match(comment)
      nuclease_concentration = md[1] unless md.blank?
      md = /([\d.]+)ng\/ul Cas[ ]*9/.match(comment)
      nuclease_concentration = md[1] unless !nuclease_concentration || md.blank?
      md = /guide[s]* ([\d.]+)ng/.match(comment)
      grna_concentration = md[1] unless md.blank?
      md = /gRNA['s]* x \d[ ]*([\d.]+)ng/.match(comment)
      grna_concentration = md[1] unless !grna_concentration.blank? || md.blank?
      md = /Oligo ([\d.]+)ng/.match(comment)
      unless md.blank?
        vector_concentration = md[1] 
        plasmid_preparation = 'Oligo'
      end
      delivery_method = 'Cytoplasmic Injection'

      save_experiment_variables(id, {:nuclease_concentration => nuclease_concentration, :grna_concentration => grna_concentration, :vector_concentration => vector_concentration, :delivery_method => delivery_method, :plasmid_preparation => plasmid_preparation})
    end

    remove_column :mutagenesis_factors, :nuclease
    remove_column :mutagenesis_factors, :vector_id

    remove_column :mi_attempts, :founder_pcr_num_assays
    remove_column :mi_attempts, :founder_pcr_num_positive_results
    remove_column :mi_attempts, :founder_surveyor_num_assays
    remove_column :mi_attempts, :founder_surveyor_num_positive_results
    remove_column :mi_attempts, :founder_t7en1_num_assays
    remove_column :mi_attempts, :founder_t7en1_num_positive_results
    remove_column :mi_attempts, :founder_loa_num_assays
    remove_column :mi_attempts, :founder_loa_num_positive_results
    remove_column :mi_attempts, :founder_num_positive_results
  end

  def self.down
    add_column :mutagenesis_factors, :nuclease, :string
    add_column :mutagenesis_factors, :vector_id, :string

    sql = <<-EOF
      UPDATE mutagenesis_factors SET (nuclease) = (
        CASE WHEN mi_attempts.mrna_nuclease = 'CAS9' THEN 'CAS9 mRNA'
             WHEN mi_attempts.mrna_nuclease = 'D10A' THEN 'D10A mRNA'
             WHEN mi_attempts.protein_nuclease = 'CAS9' THEN 'CAS9 Protein'
             WHEN mi_attempts.protein_nuclease = 'D10A' THEN 'D10A Protein'
        ELSE '' END)
      FROM mi_attempts
      WHERE mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id;

      UPDATE mutagenesis_factors SET vector_id
      FROM mutagenesis_factor_vectors
      WHERE mutagenesis_factor_vectors.mutagenesis_factor_id = mutagenesis_factors.id;
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :mrna_nuclease
    remove_column :mi_attempts, :mrna_nuclease_concentration
    remove_column :mi_attempts, :protein_nuclease
    remove_column :mi_attempts, :protein_nuclease_concentration

    remove_column :mutagenesis_factors, :individually_set_grna_concentrations
    remove_column :mutagenesis_factors, :individually_set_vector_concentrations

    remove_column :targ_rep_crisprs, :grna_concentration

    drop_table :mutagenesis_factor_vectors
  end

  def save_experiment_variables(id, variables={})
    nuclease_concentration = variables[:nuclease_concentration]
    grna_concentration = variables[:grna_concentration]
    vector_concentration = variables[:vector_concentration]
    delivery_method = variables[:delivery_method] #cytoplasmic injection, pronuclear injection, electropolis
    truncated = variables[:truncated]
    single_plasmid_delivery = variables[:single_plasmid_delivery]
    plasmid_preparation = variables[:plasmid_preparation]
    inhibitor = variables[:inhibitor]

    mi = MiAttempt.find(id)
    mf = mi.mutagenesis_factor
    unless vector_concentration.blank?
      if mf.vectors.blank?
        vector = MutagenesisFactor::Vector.new(:mutagenesis_factor_id => mf.id)
      else
        vector = mf.vectors.first
      end
      vector.concentration = vector_concentration.to_f
      vector.preparation = plasmid_preparation unless plasmid_preparation.blank?
      vector.save
    end

    unless inhibitor.blank?
      reagent = Reagent.new(:mi_attempt_id => mi.id, :reagent_name => inhibitor)
      reagent.save
    end

    unless nuclease_concentration.blank?
      unless mi.protein_nuclease.blank?
        mi.protein_nuclease_concentration = nuclease_concentration.to_f        
      else
        mi.mrna_nuclease_concentration = nuclease_concentration.to_f
      end
    end

    unless truncated.blank?
      crisprs = mf.crisprs
      crisprs.each{|c| c.truncated_guide = true; c.save}
    end

    mi.delivery_method = delivery_method unless delivery_method.blank?
    mi.save

    mf.grna_concentration = grna_concentration.to_f unless grna_concentration.blank?
    mf.guides_generated_in_plasmid = single_plasmid_delivery unless single_plasmid_delivery.blank?
    mf.save

  end
    

end
