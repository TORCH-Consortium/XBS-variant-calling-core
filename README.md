# compleX Bacterial Sample (XBS) variant caller.
Paper: Comprehensive and accurate genetic variant identification from contaminated and low coverage Mycobacterium tuberculosis whole genome sequencing data.
Authors: Tim H. Heupink, Lennert Verboven, Robin M. Warren, Annelies Van Rie.
Contact: tim.heupink@uantwerpen.be and lennert.verboven@uantwerpen.be

Introduction.
The XBS variant caller is designed to call genomic variants from bacterial samples with excessive contamination or low coverage. The nature of the variant filtering also allows XBS to identify variants in complex genomic regions, as long as these have similar statistical annotations (e.g. depth or mapping quality) to the variants provided in the truth set. XBS was designed with Mycobacterium tuberculosis in mind, but is applicable for all bacterial species provided a reference genome and truth variant set are provided.

Important note: we are currenlty building this pipeline in Nextflow, so a more user-friendly verion will be available soon.

Installation.
Simply copy the bash scripts to your local machine.
Ensure that the scripts' paths to the required tools and files are correct and available.

We used the following versions and files:
BWA 0.7.17
JAVA 8.131
GATK 4.1.4.1
SAMTOOLS 1.9
REFERENCE NC_000962.3

For the truth vcf’s provide as many trustable variants as possible. We recommend variants that have been confidently observed many times, preferably independently. Examples of such variants are lineage markers and drug resistance conferring mutations.

Running.
Call the haplotypes for each sample using script 1, ensure that the sample info is supplied under 'required info'. The script can be run from the terminal as follows: 
sh XBS_calling_core_step_1_sample_prep.sh (should work on Linux and Mac)
This step can be run in parallel for the samples to speed up the analyses.
Several QC metrics will be output to the stats directory, use these to determine which samples pass QC for subsequent analysis. A minimum mean depth of coverage of 10x and breadth of coverage of 90% is recommended for most analyses.

Next joint-call all the samples of interest that have passes your QC using script 2, ensure that all gvcf’s are indicated under 'required info'.The script can be run from the terminal as follows: 
sh XBS_calling_core_step_2_joint_calling_and_filtering.sh (should work on Linux and Mac)
Where required annotations with insufficient variation (often AS_MQRankSum) can be excluded from VQSR. The script will produce a filtered vcf for both the SNPs and the INDELs.

Future versions will include a more user friendly interface and facilitate high-throughput analysis of large datasets.

Please contact us for any further details.
