#!/bin/bash
#SBATCH --account=def-tkitzler
#SBATCH --time=03:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2

module load gatk/4.1.8.1
export GATK_JAR=/cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-4.1.8.1/gatk-package-4.1.8.1-local.jar
export reference=$MUGQIC_INSTALL_HOME/genomes/species/Homo_sapiens.GRCh38/genome/Homo_sapiens.GRCh38.fa

sm=$1

java -Xms4G -Xmx4G -jar $GATK_JAR BaseRecalibrator \
  -I aligned_${sm}"_"markdup.bam \
  -R $reference \
  -O aligned_${sm}"_"markdup_bqsr.report \
  --known-sites BQSR/Homo_sapiens_assembly38.dbsnp138.vcf \
  --known-sites BQSR/Homo_sapiens_assembly38.known_indels.vcf.gz \
  --known-sites BQSR/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

java -Xms2G -Xmx2G -jar $GATK_JAR ApplyBQSR \
  -I aligned_${sm}"_"markdup.bam \
  -R $reference \
  --bqsr-recal-file aligned_${sm}"_"markdup_bqsr.report \
  -O aligned_${sm}"_"markdup_bqsr.bam