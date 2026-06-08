cwlVersion: v1.2
class: CommandLineTool

label: "Flagstat parser"

baseCommand: ["python3"]

inputs:
  flagstat_file:
    type: File
    inputBinding:
      position: 1
  
  ok_threshold:
    type: int
    default: 95
    inputBinding:
      position: 2
  
  pot_threshold:
    type: int
    default: 80
    inputBinding:
      position: 3

outputs:
  status_output:
    type: File
    outputBinding:
      glob: "status.txt"
  
  mapping_percent:
    type: File
    outputBinding:
      glob: "mapping_percent.txt"

arguments:
  - "-c"
  - |
    import sys, re
    with open(sys.argv[1]) as f:
        content = f.read()
    match = re.search(r'(\d+)\s+\+\s+0\s+mapped\s+\((\d+\.?\d*)%', content)
    if match:
        percent = float(match.group(2))
        ok = int(sys.argv[2])
        pot = int(sys.argv[3])
        if percent >= ok:
            status = "OK"
        elif percent >= pot:
            status = "pot OK"
        else:
            status = "FAIL"
        # Записываем статус
        with open("status.txt", "w") as out:
            out.write(f"{status}\n")
        # Записываем процент
        with open("mapping_percent.txt", "w") as out:
            out.write(f"{percent}\n")
    else:
        with open("status.txt", "w") as out:
            out.write("ERROR\n")
        with open("mapping_percent.txt", "w") as out:
            out.write("0\n")
        sys.exit(1)
