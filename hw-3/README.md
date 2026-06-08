# HW-3: картирование ридов и CWL-пайплайн

Выполнены:
* поиск и скачивание данных из NCBI SRA;
* скачивание референсного генома;
* установка и проверка консольных инструментов для анализа данных;
* реализация скрипта для оценки качества картирования;
* сборка и запуск пайплайна на CWL;
* визуализация DAG пайплайна.

## Что имеется в папке `hw-3`

### Описание данных и установки
* [SRA данные для анализа.md](./SRA%20данные%20для%20анализа.md) — описание выбранного SRA-акцессиона и команды для скачивания данных.
* [Guideline CWL install.md](./Guideline%20CWL%20install.md) — инструкция по установке CWL и необходимых компонентов.
* [Visualization description.md](./Visualization%20description.md) — описание визуализации DAG и отличий DAG от блок-схемы.

### Скрипты
* [scripts/run_mapping.sh](./scripts/run_mapping.sh) — bash-скрипт для выполнения картирования и оценки качества.
* [scripts/parse_flagstat.py](./scripts/parse_flagstat.py) — скрипт для разбора результата `samtools flagstat`.

### CWL-пайплайн
* [cwl/mapping_workflow.cwl](./cwl/mapping_workflow.cwl) — основной CWL workflow.
* [cwl/bwa_mem.cwl](./cwl/bwa_mem.cwl) — шаг выравнивания reads.
* [cwl/samtools_view.cwl](./cwl/samtools_view.cwl)
* [cwl/samtools_sort.cwl](./cwl/samtools_sort.cwl)
* [cwl/samtools_index.cwl](./cwl/samtools_index.cwl)
* [cwl/samtools_flagstat.cwl](./cwl/samtools_flagstat.cwl)
* [cwl/parse_flagstat.cwl](./cwl/parse_flagstat.cwl)
* [cwl/input_mapping.yml](./cwl/input_mapping.yml) — входные параметры workflow.

### Тестовый CWL-проект
* [cwl/test_cwl_hello_world/test.cwl](./cwl/test_cwl_hello_world/test.cwl) — тестовый Hello World workflow.
* [cwl/test_cwl_hello_world/test_cwl_input.yml](./cwl/test_cwl_hello_world/test_cwl_input.yml) — входные данные для теста.

### Результаты выполнения
* [cwl_results/flagstat.txt](./cwl_results/flagstat.txt) — результат `samtools flagstat`.
* [cwl_results/mapping_percent.txt](./cwl_results/mapping_percent.txt) — процент картированных ридов.
* [cwl_results/status.txt](./cwl_results/status.txt) — итоговый статус `OK / not OK`.
* [cwl_results/workflow.dot](./cwl_results/workflow.dot) — DAG в формате DOT.
* [cwl_results/workflow.png](./cwl_results/workflow.png) — визуализация пайплайна в PNG.
* [cwl_results/workflow.svg](./cwl_results/workflow.svg) — визуализация пайплайна в SVG.
