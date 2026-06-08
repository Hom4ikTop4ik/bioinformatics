# samtools_index.cwl

cwlVersion: v1.2
class: CommandLineTool

baseCommand: ["samtools", "index"]

inputs:
  sorted_bam:
    type: File
    inputBinding:
      position: 1

outputs:
  bai_index:
    type: File
    outputBinding:
      glob: "aligned.sorted.bam.bai"

arguments:
  - "-o"
  - "aligned.sorted.bam.bai"
