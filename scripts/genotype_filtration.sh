#!/bin/bash
#SBATCH --account=def-tkitzler
#SBATCH --account=def-tkitzler
#SBATCH --time=03:00:00
#SBATCH --mem=6G
#SBATCH --cpus-per-task=3

module load gatk/4.1.8.1
export GATK_JAR=/cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-4.1.8.1/gatk-package-4.1.8.1-local.jar
export reference=$MUGQIC_INSTALL_HOME/genomes/species/Homo_sapiens.GRCh38/genome/Homo_sapiens.GRCh38.fa

# Combine gVCFs
find . -maxdepth 1 -type f -name "*_raw_variants.g.vcf.gz" > input.list
java -Xmx6g -jar $GATK_JAR CombineGVCFs \
-R $reference \
-V input.list \
-O joint/joint_raw_variants.g.vcf.gz

# Genotype gVCF
java -Xmx6g -jar $GATK_JAR GenotypeGVCFs \
-R $reference \
-V joint/joint_raw_variants.g.vcf.gz \
-O joint/joint_raw_variants_genotype.vcf.gz

# Select indels
java -Xmx2g -jar $GATK_JAR SelectVariants \
-R $reference \
-V joint/joint_raw_variants_genotype.vcf.gz \
--select-type-to-include INDEL \
-O joint/raw_indels.vcf.gz

# Hard filtration for indels
java -Xmx2g -jar $GATK_JAR VariantFiltration \
-R $reference \
-V joint/raw_indels.vcf.gz \
-O joint/filtered_indels.vcf.gz \
-filter "QD < 2.0" --filter-name "QD2" \
-filter "QUAL < 30.0" --filter-name "QUAL30" \
-filter "FS > 200.0" --filter-name "FS200" \
-filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20"

# Sties only
java -Xmx2g -jar $GATK_JAR MakeSitesOnlyVcf \
-I joint/joint_raw_variants_genotype.vcf.gz \
-O joint/joint_raw_variants_genotype_sitesonly.vcf.gz

# VQSR for SNPs
java -Xmx6g -jar $GATK_JAR VariantRecalibrator \
-R $reference \
-V joint/joint_raw_variants_genotype_sitesonly.vcf.gz \
--trust-all-polymorphic \
-tranche 100.0 -tranche 99.95 -tranche 99.9 -tranche 99.8 -tranche 99.6 -tranche 99.5 -tranche 99.4 -tranche 99.3 -tranche 99.0 -tranche 98.0 -tranche 97.0 -tranche 90.0 \
-an QD -an MQRankSum -an ReadPosRankSum -an FS -an MQ -an SOR -an DP \
-resource:hapmap,known=false,training=true,truth=true,prior=15 VQSR/hg38/hapmap_3.3.hg38.vcf.gz \
-resource:omni,known=false,training=true,truth=true,prior=12 VQSR/hg38/1000G_omni2.5.hg38.vcf.gz \
-resource:1000G,known=false,training=true,truth=false,prior=10 VQSR/hg38/1000G_phase1.snps.high_confidence.hg38.vcf.gz \
-resource:dbsnp,known=true,training=false,truth=false,prior=7 VQSR/hg38/Homo_sapiens_assembly38.dbsnp138.vcf \
--max-gaussians 4 \
-mode SNP \
-O joint/cohort_snps.recal \
--tranches-file joint/cohort_snps.tranches \
--rscript-file joint/output_snp.plots.R

java -Xmx6g -jar $GATK_JAR ApplyVQSR \
-R $reference \
-V joint/joint_raw_variants_genotype.vcf.gz \
-O joint/snp.recalibrated.vcf.gz \
--recal-file joint/cohort_snps.recal \
--tranches-file joint/cohort_snps.tranches \
--truth-sensitivity-filter-level 99.7 \
--create-output-variant-index true \
-mode SNP

# Merge files
java -Xmx2g -jar $GATK_JAR SelectVariants \
-R $reference \
-V joint/snp.recalibrated.vcf.gz \
--select-type-to-include SNP \
-O joint/snp.recalibrated_minus_indel.vcf.gz

java -Xmx2g -jar $GATK_JAR MergeVcfs \
-I joint/snp.recalibrated_minus_indel.vcf.gz \
-I joint/filtered_indels.vcf.gz \
-O joint/output_vqsr_snps_hard_indels.vcf.gz

# Recalculate posteriors using pedigree
java -Xmx2g -jar $GATK_JAR CalculateGenotypePosteriors \
-V joint/output_vqsr_snps_hard_indels.vcf.gz \
-ped pedigree.ped \
--supporting-callsets af-only-gnomad.hg38.vcf.gz \
-O trio_refined.vcf.gz