#!/bin/bash

# ===============================================
# Read mapping pipeline script
# Quality assessment parameters
# ===============================================

# Configuration (adjustable)
MAPPED_OK_THRESHOLD=95
MAPPED_POT_THRESHOLD=80

# Paths (absolute for reliability)
BASE_DIR=~/bioinf_hw3
REF=$BASE_DIR/ref/ecoli_ref.fna
R1=$BASE_DIR/data/SRR35085086_1.fastq.gz
R2=$BASE_DIR/data/SRR35085086_2.fastq.gz
OUT_DIR=$BASE_DIR/results

# Create results directory if missing
mkdir -p $OUT_DIR

echo "========================================="
echo "Processing started: $(date)"
echo "========================================="

# Step 1: BWA mem (mapping)
echo "1. Running BWA mem..."
bwa mem $REF $R1 $R2 > $OUT_DIR/aligned.sam

# Step 2: SAM -> BAM conversion
echo "2. Converting SAM to BAM..."
samtools view -Sb $OUT_DIR/aligned.sam > $OUT_DIR/aligned.bam

# Step 3: BAM sorting
echo "3. Sorting BAM..."
samtools sort $OUT_DIR/aligned.bam -o $OUT_DIR/aligned.sorted.bam

# Step 4: BAM indexing
echo "4. Indexing BAM..."
samtools index $OUT_DIR/aligned.sorted.bam

# Step 5: Flagstat
echo "5. Running samtools flagstat..."
samtools flagstat $OUT_DIR/aligned.sorted.bam > $OUT_DIR/flagstat.txt

echo "========================================="
echo "Processing finished: $(date)"
echo "========================================="

# Step 6: Parse results (calling Python script)
echo "Mapping quality analysis:"
python3 $BASE_DIR/scripts/parse_flagstat.py $OUT_DIR/flagstat.txt $MAPPED_OK_THRESHOLD $MAPPED_POT_THRESHOLD

