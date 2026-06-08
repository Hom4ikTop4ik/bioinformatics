# samtools_flagstat.cwl

cwlVersion: v1.2
class: CommandLineTool

label: "Flagstat statistics"

baseCommand: ["samtools", "flagstat"]

inputs:
  sorted_bam:
    type: File
    label: "Sorted BAM with index"
    inputBinding:
      position: 1

outputs:
  flagstat_txt:
    type: File
    label: "Flagstat output"
    outputBinding:
      glob: "flagstat.txt"

stdout: "flagstat.txt"
