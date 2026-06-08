cwlVersion: v1.2
class: CommandLineTool

# Название инструмента
label: "Test CWL Tool"

# Базовая команда
baseCommand: echo

# Входные параметры
inputs:
  message:
    type: string
    label: "Test CWL message"
    inputBinding:
      position: 1

# Выходные данные
outputs:
  printed_message:
    type: stdout

# Куда сохранить вывод
stdout: "test_cwl_output.txt"

