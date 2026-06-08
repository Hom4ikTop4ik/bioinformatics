# samtools_sort.cwl

cwlVersion: v1.2
class: CommandLineTool

baseCommand: ["samtools", "sort"]

inputs:
  bam_file:
    type: File
    inputBinding:
      position: 1

outputs:
  sorted_bam:
    type: File
    outputBinding:
      glob: "*.sorted.bam"

arguments:
  - "-o"
  - "aligned.sorted.bam"
