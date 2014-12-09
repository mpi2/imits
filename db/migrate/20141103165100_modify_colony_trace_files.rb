class ModifyColonyTraceFiles < ActiveRecord::Migration

  class BasicTraceCall < ActiveRecord::Base
    self.table_name = :trace_calls
    attr_accessible :trace_file
    has_attached_file :trace_file, :storage => :database
    do_not_validate_attachment_file_type :trace_file
  end

  class UpColony < ActiveRecord::Base
    self.table_name = :colonies
    has_many :trace_calls, :class_name => 'BasicTraceCall', :foreign_key => 'colony_id'
  end

  class DownColony < ActiveRecord::Base
    self.table_name = :colonies
    attr_accessible :trace_file
    has_attached_file :trace_file, :storage => :database
    do_not_validate_attachment_file_type :trace_file
  end

  class BasicTraceFile < ActiveRecord::Base
    self.table_name = :trace_files
  end

  def self.up
    create_table :trace_calls do |t|
      t.integer   :colony_id, :null => false
      t.text      :file_alignment, :null => true
      t.text      :file_filtered_analysis_vcf, :null => true
      t.text      :file_variant_effect_output_txt, :null => true
      t.text      :file_reference_fa, :null => true
      t.text      :file_mutant_fa, :null => true
      t.text      :file_primer_reads_fa, :null => true
      t.text      :file_alignment_data_yaml, :null => true
      t.text      :file_trace_output, :null => true
      t.text      :file_trace_error, :null => true
      t.text      :file_exception_details, :null => true
      t.integer   :file_return_code, :null => true
      t.text      :file_merged_variants_vcf, :null => true
      t.boolean   :is_het, :null => false, :default => false
    end

    add_foreign_key :trace_calls, :colonies, :column => :colony_id, :name => 'trace_calls_colonies_fk'

    # adding attachment via PaperClip gem, adds columns trace_file_file_name, trace_file_content_type,
    # trace_file_file_size and trace_file_updated_at
    add_attachment :trace_calls, :trace_file

    add_column :trace_files, :trace_call_id, :integer, :null => true, after: :id

    UpColony.all.each do |colony|
      next if( colony.trace_file_file_name.nil? )
      puts "====================================="
      puts "Colony id #{colony.id}"
      puts "- - - - - - - - - - - - - -- - - - - "
      puts "trace_file_file_name           = #{colony.trace_file_file_name}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "trace_file_content_type        = #{colony.trace_file_content_type}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "trace_file_file_size           = #{colony.trace_file_file_size}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "trace_file_updated_at          = #{colony.trace_file_updated_at}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_alignment                 = #{colony.file_alignment}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_filtered_analysis_vcf     = #{colony.file_filtered_analysis_vcf}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_variant_effect_output_txt = #{colony.file_variant_effect_output_txt}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_reference_fa              = #{colony.file_reference_fa}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_mutant_fa                 = #{colony.file_mutant_fa}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_primer_reads_fa           = #{colony.file_primer_reads_fa}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_alignment_data_yaml       = #{colony.file_alignment_data_yaml}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_trace_output              = #{colony.file_trace_output}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_trace_error               = #{colony.file_trace_error}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_exception_details         = #{colony.file_exception_details}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_return_code               = #{colony.file_return_code}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "file_merged_variants_vcf       = #{colony.file_merged_variants_vcf}"
      # puts "- - - - - - - - - - - - - -- - - - - "
      # puts "is_het                         = #{colony.is_het}"
      puts "- - - - - - - - - - - - - -- - - - - "

      tc = BasicTraceCall.where(:colony_id => colony.id).first_or_initialize

      # copy the main attributes across
      tc.trace_file_file_name           = colony.trace_file_file_name
      tc.trace_file_content_type        = colony.trace_file_content_type
      tc.trace_file_file_size           = colony.trace_file_file_size
      tc.trace_file_updated_at          = colony.trace_file_updated_at
      tc.file_alignment                 = colony.file_alignment
      tc.file_filtered_analysis_vcf     = colony.file_filtered_analysis_vcf
      tc.file_variant_effect_output_txt = colony.file_variant_effect_output_txt
      tc.file_reference_fa              = colony.file_reference_fa
      tc.file_mutant_fa                 = colony.file_mutant_fa
      tc.file_primer_reads_fa           = colony.file_primer_reads_fa
      tc.file_alignment_data_yaml       = colony.file_alignment_data_yaml
      tc.file_trace_output              = colony.file_trace_output
      tc.file_trace_error               = colony.file_trace_error
      tc.file_exception_details         = colony.file_exception_details
      tc.file_return_code               = colony.file_return_code
      tc.file_merged_variants_vcf       = colony.file_merged_variants_vcf
      tc.is_het                         = colony.is_het

      tc.save!

      # set the new trace file trace call id field
      tf = BasicTraceFile.find_by_colony_id(colony.id)
      tf.trace_call_id = tc.id
      tf.save!

      puts "Trace file trace call id = #{tf.trace_call_id}"

      if (tc.trace_file.nil?)
        puts "Trace file for colony #{colony.id} and trace call id #{tc.id} is nil"
      else
        puts "Trace file for colony #{colony.id} and trace call id #{tc.id} is NOT nil"
      end
    end

    # set trace files trace call id to not null
    puts "setting trace files trace call id to not null"
    execute('alter table trace_files alter column trace_call_id set not null')

    # remove unneeded columns from trace_files and colonies tables

    puts "removing colony id from trace files"
    remove_column :trace_files, :colony_id

    puts "removing attachment from colonies"
    remove_attachment :colonies, :trace_file

    puts "removing columns from colonies"
    # remove_column :colonies, :trace_file_file_name
    # remove_column :colonies, :trace_file_content_type
    # remove_column :colonies, :trace_file_updated_at
    # remove_column :colonies, :trace_file_file_size
    remove_column :colonies, :file_alignment
    remove_column :colonies, :file_filtered_analysis_vcf
    remove_column :colonies, :file_variant_effect_output_txt
    remove_column :colonies, :file_reference_fa
    remove_column :colonies, :file_mutant_fa
    remove_column :colonies, :file_primer_reads_fa
    remove_column :colonies, :file_alignment_data_yaml
    remove_column :colonies, :file_trace_output
    remove_column :colonies, :file_trace_error
    remove_column :colonies, :file_exception_details
    remove_column :colonies, :file_return_code
    remove_column :colonies, :file_merged_variants_vcf
    remove_column :colonies, :is_het
  end

  def self.down

    puts "add columns to colonies"
    add_column :colonies, :file_alignment, :text, :null => true
    add_column :colonies, :file_filtered_analysis_vcf, :text, :null => true
    add_column :colonies, :file_variant_effect_output_txt, :text, :null => true
    add_column :colonies, :file_reference_fa, :text, :null => true
    add_column :colonies, :file_mutant_fa, :text, :null => true
    add_column :colonies, :file_primer_reads_fa, :text, :null => true
    add_column :colonies, :file_alignment_data_yaml, :text, :null => true
    add_column :colonies, :file_trace_output, :text, :null => true
    add_column :colonies, :file_trace_error, :text, :null => true
    add_column :colonies, :file_exception_details, :text, :null => true
    add_column :colonies, :file_return_code, :integer, :null => true
    add_column :colonies, :file_merged_variants_vcf, :text, :null => true
    add_column :colonies, :is_het, :boolean, :default => false, :null => true

    puts "add attachment colonies"
    add_attachment :colonies, :trace_file

    puts "add colony id to trace files"
    add_column :trace_files, :colony_id, :integer, :null => true, after: :id

    # NB. many trace calls per colony but here we know 1:1
    BasicTraceCall.all.each do |tc|

      puts "trace call id #{tc.id}"
      puts "trace call colony id #{tc.colony_id}"

      colony = DownColony.find_by_id(tc.colony_id)
      tf     = BasicTraceFile.find_by_trace_call_id(tc.id)

      puts "trace file id #{tf.id}"
      puts "setting colony columns"

      colony.trace_file_file_name           = tc.trace_file_file_name
      colony.trace_file_content_type        = tc.trace_file_content_type
      colony.trace_file_updated_at          = tc.trace_file_updated_at
      colony.trace_file_file_size           = tc.trace_file_file_size
      colony.file_alignment                 = tc.file_alignment
      colony.file_filtered_analysis_vcf     = tc.file_filtered_analysis_vcf
      colony.file_variant_effect_output_txt = tc.file_variant_effect_output_txt
      colony.file_reference_fa              = tc.file_reference_fa
      colony.file_mutant_fa                 = tc.file_mutant_fa
      colony.file_primer_reads_fa           = tc.file_primer_reads_fa
      colony.file_alignment_data_yaml       = tc.file_alignment_data_yaml
      colony.file_trace_output              = tc.file_trace_output
      colony.file_trace_error               = tc.file_trace_error
      colony.file_exception_details         = tc.file_exception_details
      colony.file_return_code               = tc.file_return_code
      colony.file_merged_variants_vcf       = tc.file_merged_variants_vcf
      colony.is_het
      colony.save!

      puts "set trace file colony id to #{tc.colony_id}"

      tf.colony_id = tc.colony_id
      tf.save!

      puts "Trace file colony id = #{tf.colony_id}"

      if (colony.trace_file.nil?)
        puts "Trace file for colony #{colony.id} is nil"
      else
        puts "Trace file for colony #{colony.id} is NOT nil"
      end
    end

    puts "setting trace files colony id to not null"
    execute('alter table trace_files alter column colony_id set not null')

    puts "add fk to trace files for colony id"
    add_foreign_key :trace_files, :colonies, :column => :colony_id, :name => 'trace_files_colonies_fk'

    puts "remove trace files trace call id"
    remove_column :trace_files, :trace_call_id

    puts "remove attachment from trace calls"
    remove_attachment :trace_calls, :trace_file

    puts "drop trace calls table"
    drop_table :trace_calls
  end

end