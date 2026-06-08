# samtools_view.cwl

cwlVersion: v1.2
class: CommandLineTool

label: "SAM to BAM converter"

baseCommand: ["samtools", "view", "-b"]

inputs:
  sam_file:
    type: File
    inputBinding:
      position: 1

outputs:
  bam_file:
    type: File
    outputBinding:
      glob: "*.bam"

arguments:
  - "-o"
  - "converted.bam"
