#!/bin/bash
#SBATCH --account=def-tkitzler
#SBATCH --time=01:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=34
#SBATCH --array=0-2

module load fastp
module load bwa

export reference=$MUGQIC_INSTALL_HOME/genomes/species/Homo_sapiens.GRCh38/genome/bwa_index/Homo_sapiens.GRCh38.fa

# Specify the path to the config file
config=config.txt

# Extract the sample name for the current $SLURM_ARRAY_TASK_ID
sm=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

# Extract the sample id for the current $SLURM_ARRAY_TASK_ID
id=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)

fastp -i "$sm"_"1.fq.gz" -I "$sm"_"2.fq.gz" \
    --stdout --thread 2 \
    -j "fastp-$sm.json" \
    -h "fastp-$sm.html" \
    2> "fastp-$sm.log" \
| bwa mem -v 2 -M -t 32 -p \
    -R "@RG\tID:$id\tPL:ILLUMINA\tLB:$id"_"$sm\tSM:$sm" \
    $reference - 2> "bwa-$sm.log" \
    > results_$sm.sam 

sbatch convertsamtobam.sh $sm