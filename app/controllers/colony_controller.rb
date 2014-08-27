require 'yaml'
require 'pp'

class ColonyController < ApplicationController
  def show
    @id = params[:id]
    debug = true

  #  puts "#### show"

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?

    @title = "Colony #{@colony.name} (#{@colony.trace_file_file_name})"
    marker_symbol = @colony.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
    @title = "Gene #{marker_symbol} - Colony #{@colony.name} (#{@colony.trace_file_file_name})" if marker_symbol

    show = true

    # TODO: move this into Colony.rb

    @files[:alignment] = {:filename => 'alignment.txt', :name => 'Alignment', :data => nil, :show => show}
    @files[:filtered_analysis_vcf] = {:filename => 'filtered_analysis.vcf', :name => 'Variant (vcf)', :data => nil, :show => show}
    @files[:vep_log] = {:filename => 'vep.log', :name => 'Variant (vep)', :data => nil, :show => show}
    @files[:reference] = {:filename => 'reference.fa', :name => 'Protein Sequence (reference)', :data => nil, :show => true}
    @files[:mutant_fa] = {:filename => 'mutated.fa', :name => 'Protein Sequence (mutated)', :data => nil, :show => show}
    @files[:read_seq_fa] = {:filename => 'read_seq.fa', :name => 'read_seq.fa', :data => nil, :show => false}
    @files[:variant_effect_output_txt] = {:filename => 'variant_effect_output.txt', :name => 'variant_effect_output.txt', :data => nil, :show => false}
    @files[:analysis_pileup] = {:filename => 'analysis.pileup', :name => 'analysis.pileup', :data => nil, :show => false}
    @files[:primer_reads_fa] = {:filename => 'primer_reads.fa', :name => 'Reads', :data => nil, :show => true}
    @files[:alignment_data_yaml] = {:filename => 'alignment_data.yaml', :name => 'alignment_data.yaml', :data => nil, :show => false}

    if params[:filename]
      key = params[:filename].to_sym
      if @files.has_key? key
        send_file "#{Rails.root}/public/trace_files/#{@id}/#{@files[key][:filename]}", :disposition => 'attachment'
      end

      return
    end

   # puts "#### before start check"

    folder = "#{Colony::FOLDER_OUT}/#{@id}"
    if ! File.exists?(folder)
      return;
    end

    yaml_file = "#{Colony::FOLDER_OUT}/#{@id}/#{@files[:alignment_data_yaml][:filename]}"
    @alignment_data = {}
    @alignment_data = YAML.load_file(yaml_file) if File.exists?(yaml_file) && File.size?(yaml_file)

  #  pp @alignment_data

    @deletions = []

  #  puts "#### start check"

    if @alignment_data.has_key? 'deletions'
    #  puts "#### found deletions"
      @alignment_data['deletions'].keys.each do |kk|
        array = @alignment_data['deletions'][kk]
    #  puts "#### found array"
      pp array
        array.each do |frame|
          @deletions.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
        end
      end
    end

    @insertions = []

    if @alignment_data.has_key? 'insertions'
    #  puts "#### found insertions"
      @alignment_data['insertions'].keys.each do |kk|
        array = @alignment_data['insertions'][kk]
        array.each do |frame|
          @insertions.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
        end
      end
    end

    @target_sequence = "Target sequence start: #{@alignment_data['target_sequence_start']} - Target sequence end: #{@alignment_data['target_sequence_end']}"

#    deletions:
#  "270":
#  - length: "1"
#    read: reverse
#    seq: G
#  "530":
#  - length: "1"
#    read: reverse
#    seq: T
#insertions: {}
#
#target_sequence_end: 139237356
#target_sequence_start: "139236816"




    @ok = false

    @files.keys.each do |key2|

        data = nil

        file = "#{folder}/#{@files[key2][:filename]}"
        if File.exists?(file) && File.size?(file)
          file = File.open(file, "rb")
          data = file.read

          data = data.strip || data

          @files[key2][:data] = data

          @ok = true if data
        end
    end

    #folder = "#{Colony::FOLDER_OUT}/#{@id}"
    #if File.exists?(folder)
    #
    #  @alignment = nil
    #
    #  file = "#{folder}/alignment.txt"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @alignment = file.read
    #
    #    @alignment = @alignment.strip || @alignment
    #
    #    @files[:alignment] = {:name => 'Alignment', :data => @alignment}
    #  end
    #
    #
    #
    #
    #  @filtered_analysis_vcf = nil
    #
    #  file = "#{folder}/filtered_analysis.vcf"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @filtered_analysis_vcf = file.read
    #
    #    @filtered_analysis_vcf = @filtered_analysis_vcf.strip || @filtered_analysis_vcf
    #
    #    @files[:filtered_analysis_vcf] = {:name => 'filtered_analysis_vcf', :data => @filtered_analysis_vcf}
    #  end
    #
    #
    #
    #
    #
    #
    #  @vep_log = nil
    #
    #  file = "#{folder}/vep.log"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @vep_log = file.read
    #
    #    @vep_log = @vep_log.strip || @vep_log
    #
    #    @files[:vep_log] = {:name => 'vep_log', :data => @vep_log}
    #  end
    #
    #
    #
    #
    #
    #
    #  @mutant_fa = nil
    #
    #  file = "#{folder}/mutant.fa"
    #  if File.exists?(file)
    #    file = File.open(file, "rb")
    #    @mutant_fa = file.read
    #
    #    @mutant_fa = @mutant_fa.strip || @mutant_fa
    #
    #    @files[:vep_log] = {:name => 'mutant_fa', :data => @mutant_fa}
    #  end
    #
    #
   # end
  end

  def index_old
    @colonies = []

    Colony.all.each do |colony|
      @colonies.push colony if colony.trace_data_available
    end
  end

  def index
    @colonies = Colony.all
  end
end
