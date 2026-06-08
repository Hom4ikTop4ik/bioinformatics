# mapping_workflow.cwl

# Полный пайплайн для оценки качества картирования:
# 1. BWA mem           - выравнивание ридов на референс
# 2. samtools view     - конвертация SAM в BAM
# 3. samtools sort     - сортировка BAM
# 4. samtools index    - индексация BAM
# 5. samtools flagstat - статистика
# 6. Python parser     - оценка качества (OK/pot OK)

cwlVersion: v1.2
class: Workflow

inputs:
  reference:
    type: File
    label: "Reference genome (indexed with bwa)"
  
  reads_R1:
    type: File
    label: "FASTQ reads forward (R1)"
  
  reads_R2:
    type: File
    label: "FASTQ reads reverse (R2)"
  
  ok_threshold:
    type: int
    label: "OK mapping threshold (percent)"
    default: 95
  
  pot_threshold:
    type: int
    label: "Potential OK threshold (percent)"
    default: 80

outputs:
  flagstat_result:
    type: File
    outputSource: flagstat/flagstat_txt
  
  status_output:
    type: File
    outputSource: parse/status_output
  
  mapping_percent:
    type: File
    outputSource: parse/mapping_percent

steps:
  bwa:
    run: bwa_mem.cwl
    in:
      reference: reference
      reads_R1: reads_R1
      reads_R2: reads_R2
    out: [sam_file]
  
  view:
    run: samtools_view.cwl
    in:
      sam_file: bwa/sam_file
    out: [bam_file]
  
  sort_bam:
    run: samtools_sort.cwl
    in:
      bam_file: view/bam_file
    out: [sorted_bam]
  
  index:
    run: samtools_index.cwl
    in:
      sorted_bam: sort_bam/sorted_bam
    out: [bai_index]
  
  flagstat:
    run: samtools_flagstat.cwl
    in:
      sorted_bam: sort_bam/sorted_bam
    out: [flagstat_txt]
  
  parse:
    run: parse_flagstat.cwl
    in:
      flagstat_file: flagstat/flagstat_txt
      ok_threshold: ok_threshold
      pot_threshold: pot_threshold
    out: [status_output, mapping_percent]
