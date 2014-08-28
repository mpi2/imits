require 'yaml'

class ColonyController < ApplicationController
  def show
    @id = params[:id]
    debug = true

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?

    @title = "Colony #{@colony.name} (#{@colony.trace_file_file_name})"
    marker_symbol = @colony.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
    @title = "Gene #{marker_symbol} - Colony #{@colony.name} (#{@colony.trace_file_file_name})" if marker_symbol

    show = true

    # TODO: move this into Colony.rb

    @files[:alignment] = {:filename => 'alignment.txt', :name => 'Alignment', :data => nil, :show => show, :split => true, :titles=> ['Reference Sequence', 'Mutated Sequence'], :ids => ['ref_seq', 'seq_1']}
    @files[:filtered_analysis_vcf] = {:filename => 'filtered_analysis.vcf', :name => 'Variant (vcf)', :data => nil, :show => show}
    @files[:variant_effect_output_txt] = {:filename => 'variant_effect_output.txt', :name => 'Variant (vep)', :data => nil, :show => true}
    @files[:reference] = {:filename => 'reference.fa', :name => 'Protein Sequence (reference)', :data => nil, :show => true, :id => 'ref_protein'}
    @files[:mutant_fa] = {:filename => 'mutated.fa', :name => 'Protein Sequence (mutated)', :data => nil, :show => true, :id => 'protein_seq'}
    @files[:read_seq_fa] = {:filename => 'read_seq.fa', :name => 'read_seq.fa', :data => nil, :show => false}
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

    folder = "#{Colony::FOLDER_OUT}/#{@id}"
    if ! File.exists?(folder)
      return;
    end

    yaml_file = "#{Colony::FOLDER_OUT}/#{@id}/#{@files[:alignment_data_yaml][:filename]}"
    @alignment_data = {}
    @alignment_data = YAML.load_file(yaml_file) if File.exists?(yaml_file) && File.size?(yaml_file)

    @deletions = []

    if @alignment_data.has_key? 'deletions'
      @alignment_data['deletions'].keys.each do |kk|
        array = @alignment_data['deletions'][kk]
        array.each do |frame|
          @deletions.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
        end
      end
    end

    @insertions = []

    if @alignment_data.has_key? 'insertions'
      @alignment_data['insertions'].keys.each do |kk|
        array = @alignment_data['insertions'][kk]
        array.each do |frame|
          @insertions.push "#{kk}: length: #{frame['length']} - read: #{frame['read']} - seq: #{frame['seq']}"
        end
      end
    end

    @target_sequence = "Target sequence start: #{@alignment_data['target_sequence_start']} - Target sequence end: #{@alignment_data['target_sequence_end']}"

    @ok = false

    @files.keys.each do |key2|

        data = nil

        file = "#{folder}/#{@files[key2][:filename]}"
        if File.exists?(file) && File.size?(file)
          file = File.open(file, "rb")


          if @files[key2][:split] == true
            data  = []
            file.each_line do |line|
              data << line.strip
            end
          else
            data = file.read
            data = data.strip || data
          end

          @files[key2][:data] = data

          @ok = true if data
        end
    end

    # get rid of first line (file name)
    # remove line breaks

    if @files[:primer_reads_fa][:data]
      @files[:primer_reads_fa][:data] = @files[:primer_reads_fa][:data].lines.to_a[1..-1].join
      @files[:primer_reads_fa][:data].gsub!(/\s+/, "")
    end

  end

  def index
    @colonies = Colony.all
  end
end
