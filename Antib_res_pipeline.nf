nextflow.enable.dsl = 2
//
// don't forget the nextflow.config in the folder
params.indir = null
params.outdir = "results" // where to output by ddefault the results of this script
// Reference genome, in this case a SRST2 database in fasta format
params.ref_gen = false
//
// make infolder mandatory
if (!params.indir) {
    error "ERROR: Please specify a directory to work on"
}
//
// make reference GENE CARD mandatory. For srst2
if (!params.ref_gen) {
    error "ERROR: Please specify REFERENCE GENE CARD fasta file for SRST2"
}

// Trimming, cutting of fastq files (bad seqs, adapters, bad reads...) RTFM
process fastP {
  // container "/home/cq/singularity_containers/fastp:0.23.2--hb7a2d85_2" // when local
  container "https://depot.galaxyproject.org/singularity/fastp:0.23.2--hb7a2d85_2"
  publishDir "${params.outdir}", mode: "copy", overwrite: true
  input:
    path infile_fastq
    // val accession
  output:
    path "${infile_fastq.getSimpleName()}*fastp.fastq", emit: fastq_trimmed
    path "${infile_fastq.getSimpleName()}*fastp.html", emit: fastp_report
    path "${infile_fastq.getSimpleName()}*fastp.json", emit: fastp_json_report
    // path "${infile_fastq.getSimpleName()}*"// the * is needed for paired runs because they produce more than one fastaq, otherwise it will give an error
  script:
    // fastq (single end)
    """
    fastp -i "${infile_fastq}" -o "${infile_fastq.getSimpleName()}_fastp.fastq" -h "${infile_fastq.getSimpleName()}_fastp.html" -j "${infile_fastq.getSimpleName()}_fastp.json"
    """
    }

// Process to assess fastq quality
process fastQC {
  // container "/home/cq/singularity_containers/fastqc:0.11.9--hdfd78af_1" // when local
  container "https://depot.galaxyproject.org/singularity/fastqc:0.11.9--hdfd78af_1"
  publishDir "${params.outdir}", mode: "copy", overwrite: true
  input:
    path infile_fastq
    // val accession
  output:
    path "${infile_fastq.SimpleName}*_fastqc.zip" , emit: zipped_fqc
    path "${infile_fastq.SimpleName}*_fastqc.html"// the * is needed for paired runs because they produce more than one fastaq, otherwise it will give an error
  script:
    """
    fastqc ${infile_fastq}
    """
}

// SRST2 process
// with reference genome
process srst2{
  publishDir "${params.outdir}", mode: "copy", overwrite: true // careful with move mode
  // container "/home/cq/singularity_containers/srst2:0.2.0--py27_2" // when local
  container "https://depot.galaxyproject.org/singularity/srst2:0.2.0--py27_2"
  input:
  path infile_fastq
  path ref_gen
  output:
  path "*.txt"
  script:
  """
  srst2 --input_se ${infile_fastq} --output out_summary --log --gene_db "${ref_gen}"
  """
}

  workflow {
    // Get fastaq files from a folder name. use "/" to make it folders on the fly
    Fastq_get_outchannel = channel.fromPath("${params.indir}/*.fastq").collect()
    // Fastq_get_outchannel.flatten().view() // debug
    // Trimming of fastq files with fastp. One file at the time
    Trimming_outchannel = fastP(Fastq_get_outchannel.flatten())
    // Quality report only on trimmed fastq files. Fastqc can deal w multiple files simultaneously
    trimmed_fastqs_collected = Trimming_outchannel.fastq_trimmed.collect()
    // trimmed_fastqs_collected.view() // debug
    Quality_out = fastQC(trimmed_fastqs_collected)
    //
    reference = channel.fromPath("${params.ref_gen}")
    // testing sorting of trimmed_fastqs_collected. ".collect(sort: true)" gave inverted the results (!?)
    // trimmed_fastqs_collected_sorted = trimmed_fastqs_collected.toSortedList(). It gave a nested list (!?)
    // trimmed_fastqs_collected_sorted.view() // debug
    Srst2_run_outchannel = srst2(trimmed_fastqs_collected, reference)
    // srst2 accepts multiple fastq files at the same time. It seems it process them sequentially. e.g.:
    // srst2 --input_se patient*_fastp.fastq --log --gene_db ../CARD_v3.0.8_SRST2.fasta --output srst2
    }
