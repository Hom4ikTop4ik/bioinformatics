# bwa_mem.cwl

cwlVersion: v1.2
class: CommandLineTool

baseCommand: ["bwa", "mem"]

inputs:
  reference:
    type: File
    inputBinding:
      position: 1
    secondaryFiles:
      - ".amb"
      - ".ann"
      - ".bwt"
      - ".pac"
      - ".sa"
  
  reads_R1:
    type: File
    inputBinding:
      position: 2
  
  reads_R2:
    type: File
    inputBinding:
      position: 3

  threads:
    type: int?
    default: 2
    inputBinding:
      prefix: "-t"
      position: 0

outputs:
  sam_file:
    type: File
    outputBinding:
      glob: "aligned.sam"

stdout: "aligned.sam"
