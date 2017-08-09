class ColonyController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def show
    @id = params[:id]
    debug = true

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?
    return if @colony.allele_call.nil?


    marker_symbol = @colony.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
    if marker_symbol
      @title         = "Gene #{marker_symbol} - Colony #{@colony.name}"
    else
      @title         = "Colony #{@colony.name}"
    end
    @trace_file_name = "#{@colony.try(:allele_call).try(:trace_file_file_name)}"

    @files[:alignment]                 = {:filename => 'alignment.txt', :name => 'Alignment', :data => @colony.allele_call.targeted_file_alignment, :show => true, :split => true, :titles=> ['Reference Sequence', 'Mutated Sequence'], :ids => ['ref_seq', 'seq_1']}
    @files[:filtered_analysis_vcf]     = {:filename => 'filtered_analysis.vcf', :name => 'Variant (vcf)', :data => @colony.allele_call.filtered_analysis_vcf, :show => true}
    @files[:merged_variants_vcf]       = {:filename => 'merged_variants.vcf', :name => 'Variant (merged vcf)', :data => @colony.allele_call.merged_variants_vcf, :show => true}
    @files[:variant_effect_output_txt] = {:filename => 'variant_effect_output.txt', :name => 'Variant (vep)', :data => @colony.allele_call.variant_effect_predictor_output, :show => true}
    @files[:reference]                 = {:filename => 'reference.fa', :name => 'Protein Sequence (reference)', :data => @colony.allele_call.reference_fa, :show => true, :id => 'ref_protein'}
    @files[:mutant_fa]                 = {:filename => 'mutated.fa', :name => 'Protein Sequence (mutated)', :data => @colony.allele_call.mutant_fa, :show => true, :id => 'protein_seq'}
    @files[:primer_reads_fa]           = {:filename => 'primer_reads.fa', :name => 'Reads', :data => @colony.allele_call.primer_reads_fa, :show => true}

    @files[:debug_output]              = {:filename => 'debug_output.txt', :name => 'crispr_damage_analysis output (debug)', :data => @colony.allele_call.trace_output, :show => ! Rails.env.production?}
    @files[:debug_errors]              = {:filename => 'debug_errors.txt', :name => 'crispr_damage_analysis errors (debug)', :data => @colony.allele_call.trace_error, :show => ! Rails.env.production?}
    @files[:debug_exception]           = {:filename => 'debug_exception.txt', :name => 'crispr_damage_analysis exception (debug)', :data => @colony.allele_call.exception_details, :show => ! Rails.env.production?}

    if params[:filename]
      key = params[:filename].to_sym
      if @files.has_key? key
        send_data @files[key][:data], :filename => @files[key][:filename], :disposition => 'attachment'
      end

      return
    end

    @deletions = @colony.allele_call.deletions

    @insertions = @colony.allele_call.insertions

    @ok = false

    @files.keys.each do |key2|

        data = nil

        if @files[key2][:data]

          if @files[key2][:split] == true
            data  = []
            @files[key2][:data].each_line do |line|
              data << line.strip
            end
          else
            data = @files[key2][:data]
            data = data.strip || data
          end

          @files[key2][:data] = data

          @ok = true if data
        end
    end

  end

  def phenotype_attempts_new
    @colony = Colony.find_by_name(params[:mi_attempt_colony_name])

    redirect_to :controller => 'phenotype_attempts', :action => :new, :colony_id => @colony.try(:id)
  end

  def mut_nucleotide_sequences
    @colony = Colony.find_by_id(params[:id])

    @mutsequences = @colony.get_mutant_nucleotide_sequence_features

    respond_with @mutsequences do |format|
      format.json do
        render :json => @mutsequences
      end
    end

  end
end
