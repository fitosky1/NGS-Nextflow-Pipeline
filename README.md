# NGS Pipeline
## Antibiotic resistance

Basic *Nextflow* pipeline script to detect antibiotic resistance using NGS data.  
Tested only with single end *Illumina* fastq files present in one folder (e.g. 'rawdata')

Using modules:  
- fastp for fastq files trimming.
- fasqc for fastq quality control.
- srst2 for antibiotic resistance prediction (https://github.com/katholt/srst2#output-files).
    

Using *Singularity* images from  
https://depot.galaxyproject.org/singularity/


Using Antibiotic Resistance gene cards from  
https://github.com/katholt/srst2/blob/master/data/CARD_v3.0.8_SRST2.fasta


**Usage:**  
`nextflow Antib_res_pipeline.nf --indir <rawdata> --ref_gen CARD_v3.0.8_SRST2.fasta -profile singularity`

sample result folder in "saved_results"
