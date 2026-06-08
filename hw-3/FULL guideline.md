## Этап 0: Начало WSL
### Обновление WSL
```bash
sudo apt update && sudo apt upgrade -y

# Я устанавливал всё это. Возможно, этого даже будет мало для чистого WSL или Linux
sudo apt install -y curl wget git build-essential gzip libncurses-dev libz-dev libbz2-dev liblzma-dev meson ninja-build g++ pkg-config cmake sra-toolkit
```

### Создание рабочих папок
```bash
mkdir -p ~/bioinf_hw3/{data,ref,hello_world_results,cwl_results,scripts,cwl}
cd ~/bioinf_hw3
```

### Установка окружения
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3
~/miniconda3/bin/conda init bash
source ~/.bashrc
```

---

## Этап 1: Установка инструментов
```bash
# FastQC (через wget, так как его нет в conda)
wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip
unzip fastqc_v0.12.1.zip
chmod +x FastQC/fastqc
echo 'export PATH=$PATH:~/bioinf_hw3/FastQC' >> ~/.bashrc

# BWA (через conda)
conda install -c bioconda bwa

# Samtools (через conda)
conda install -c bioconda samtools

# FreeBayes (через conda)
conda install -c bioconda freebayes

# Дополнительно: установите другие полезные инструменты
conda install -c bioconda bcftools  # для работы с VCF-файлами
conda install -c bioconda bedtools  # для работы с BED-файлами

# Обновите PATH и проверьте
source ~/.bashrc

# Проверка всех установок
fastqc --version
bwa 2>&1 | head -3
samtools --version
freebayes --version

which fastqc
which bwa
which samtools
which freebayes
```



---

## Этап 2: скачать исходные данные для обработки

1) Зайти на `https://www.ncbi.nlm.nih.gov/sra`
2) Искать `Escherichia coli AND "illumina" AND "pair end" AND "wgs"`
3) Выбрать какой-нибудь (выберу маленький) — SRX30198562 (он же SRR35085086 внутри страницы)
```bash
cd ~/bioinf_hw3/data

# Скачиваем (139 MB, быстро)
prefetch SRR35085086

# Извлекаем FASTQ (парные концы)
fastq-dump --split-files --gzip SRR35085086

# Проверяем, что всё скачалось
ls -lh SRR35085086*.fastq.gz
```

Проверка:
```bash
# Посмотреть первые несколько строк
zcat SRR35085086_1.fastq.gz | head -8

# Посчитать количество ридов (для пары)
echo "Reads in R1:"
zcat SRR35085086_1.fastq.gz | echo $((`wc -l`/4))
echo "Reads in R2:"
zcat SRR35085086_2.fastq.gz | echo $((`wc -l`/4))

# Должно быть одинаковое число!
```


## Этап 3: Ручной запуск пайплайна
### 3.1. Скачайте и индексируйте референс E. coli 
(по ссылке из PDF ДЗ-3)
```bash
cd ~/bioinf_hw3/ref

# Скачиваем актуальный референс E. coli K-12 (штамм MG1655)
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

# Распаковываем
gunzip GCF_000005845.2_ASM584v2_genomic.fna.gz

# Переименовываем для удобства
mv    GCF_000005845.2_ASM584v2_genomic.fna    ecoli_ref.fna

# Индексируем для BWA (создаст .amb, .ann, .bwt, .pac, .sa)
bwa index ecoli_ref.fna

# Индексируем для samtools (создаст .fai)
samtools faidx ecoli_ref.fna
```

### 3.2. Запустите BWA mem (картирование)
```bash
cd ~/bioinf_hw3

# bwa mem <референс> <R1> <R2> > <output.sam>
bwa mem ref/ecoli_ref.fna data/SRR35085086_1.fastq.gz data/SRR35085086_2.fastq.gz > hello_world_results/aligned.sam
```

Что делает BWA mem:
* Берёт каждый рид из FASTQ
* Ищет его позицию в геноме (с учётом mismatches, gaps)
* Выдаёт SAM-строку для каждого выравнивания
* Время выполнения: ~2-5 минут (965k ридов)

Следите за выводом: BWA печатает прогресс:
```text
[M::bwa_idx_load] load 0... done
[M::process] read 100000 sequences ...
```


### 3.3. Конвертируйте SAM → BAM (бинарный)
```bash
# SAM в BAM (samtools view -b = output BAM)
samtools view -Sb hello_world_results/aligned.sam > hello_world_results/aligned.bam
```
Зачем BAM — Быстрее для последующих операций:
* SAM текстовый → 3-5 ГБ
* BAM сжатый → 300-500 МБ

### 3.4. Сортируйте BAM
```bash
samtools sort hello_world_results/aligned.bam -o hello_world_results/aligned.sorted.bam
```
Зачем сортировка?
* FreeBayes/BCFtools требуют сортированный BAM по координатам
* Быстрее искать риды в регионе

### 3.5. Индексируйте BAM
```bash
samtools index hello_world_results/aligned.sorted.bam
```
Создаст файл: aligned.sorted.bam.bai
Зачем индекс? Позволяет мгновенно достать риды из конкретного участка генома.

### 3.6. Запустите flagstat
```bash
samtools flagstat hello_world_results/aligned.sorted.bam > hello_world_results/flagstat.txt
cat hello_world_results/flagstat.txt
```

Ну и посмотреть проценты:
```bash
grep "mapped (" hello_world_results/flagstat.txt
```


### 3.7. дополонительно Быстрая оценка качества
```bash
# Запустите FastQC на одном из файлов
fastqc data/SRR35085086_1.fastq.gz -o hello_world_results/

# В WSL без GUI можно открыть HTML в браузере Windows:
# Откройте hello_world_results/SRR35085086_1_fastqc.html через /mnt/c/...
```


## Этап 4. Автоматизация
```bash
cd ~/bioinf_hw3/scripts
nano run_mapping.sh
```

Вставить
```bash
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
OUT_DIR=$BASE_DIR/cwl_results

# Create cwl_results directory if missing
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
```

### 4.2. Python скриптик для парсинга
```bash
cd ~/bioinf_hw3/scripts
nano parse_flagstat.py
```

Вставить
```python
#!/usr/bin/env python3
"""
Parser for samtools flagstat output
Calculates mapping percentage and returns OK/potetial OK (pot OK)/FAIL
"""

import re
import sys

def parse_flagstat(filename, ok_threshold=95, pot_threshold=80):
    """
    Parse flagstat file and return percentage of mapped reads
    """
    try:
        with open(filename, 'r') as f:
            content = f.read()
        
        # Look for the total mapped reads line
        # Format: "1700946 + 0 mapped (87.91% : N/A)"
        match = re.search(r'(\d+)\s+\+\s+0\s+mapped\s+\((\d+\.?\d*)%', content)
        
        if match:
            mapped_reads = int(match.group(1))
            percent = float(match.group(2))
            
            # Quality assessment
            if percent >= ok_threshold:
                status = "OK"
                status_icon = "✅"
            elif percent >= pot_threshold:
                status = "pot OK"
                status_icon = "⚠️"
            else:
                status = "FAIL"
                status_icon = "❌"
            
            # Print results
            print(f"\n{'='*40}")
            print(f"MAPPING RESULTS")
            print(f"{'='*40}")
            print(f"Mapped reads: {mapped_reads:,}")
            print(f"Mapping percentage: {percent}%")
            print(f"OK threshold: ≥{ok_threshold}%")
            print(f"POT OK threshold: ≥{pot_threshold}%")
            print(f"{'='*40}")
            print(f"STATUS: {status_icon} {status}")
            print(f"{'='*40}\n")
            
            # Additional information from flagstat
            proper_match = re.search(r'(\d+)\s+\+\s+0\s+properly paired\s+\((\d+\.?\d*)%', content)
            if proper_match:
                proper_percent = float(proper_match.group(2))
                print(f"Properly paired: {proper_percent}%")
            
            singleton_match = re.search(r'(\d+)\s+\+\s+0\s+singletons\s+\((\d+\.?\d*)%', content)
            if singleton_match:
                singleton_percent = float(singleton_match.group(2))
                print(f"Singletons: {singleton_percent}%")
            
            return percent, status
            
        else:
            print("ERROR: Could not find mapped reads line in flagstat output")
            return None, "ERROR"
            
    except FileNotFoundError:
        print(f"ERROR: File {filename} not found")
        return None, "ERROR"

if __name__ == "__main__":
    # Read command line arguments
    if len(sys.argv) < 2:
        print("Usage: python3 parse_flagstat.py <flagstat_file> [ok_threshold] [pot_threshold]")
        sys.exit(1)
    
    flagstat_file = sys.argv[1]
    ok_thresh = int(sys.argv[2]) if len(sys.argv) > 2 else 95
    pot_thresh = int(sys.argv[3]) if len(sys.argv) > 3 else 80
    
    parse_flagstat(flagstat_file, ok_thresh, pot_thresh)
```

### 4.3. Запуск
```bash
chmod +x ~/bioinf_hw3/scripts/run_mapping.sh
chmod +x ~/bioinf_hw3/scripts/parse_flagstat.py

cd ~/bioinf_hw3/scripts
./run_mapping.sh
```

## Этап 5: CWL
### 5.1. Окружение
```bash
# Возвращаемся в корневую папку
cd ~/bioinf_hw3

# Создаём отдельное окружение для CWL (Python 3.9 — стабильная версия)
conda create -n cwl_env python=3.9 -y

# Активируем окружение
conda activate cwl_env

# Проверяем, что мы внутри окружения
which python
# Должно показать: /home/voblgobl/miniconda3/envs/cwl_env/bin/python
```

### 5.2. Установка CWLtool
```bash
conda install -c conda-forge cwltool schema-salad -y

# # через pip install cwltool не хочет устанавливаться из-за проблем с DNS, кажется
# sudo apt install cwltool

# # Устанавливаем утилиты для визуализации и валидации
# pip install schema-salad
```

### 5.3. Устанавливаем Graphviz (для визуализации DAG)
```bash
# Графовая утилита для создания PNG/SVG без GUI
sudo apt install -y graphviz

# Проверяем
dot -V
# Должно показать, например: dot - graphviz version 14.1.2 (20260126.1125)
```

cwltool      | Запускает CWL-пайплайны (runner)
schema-salad | Проверяет синтаксис CWL файлов
graphviz     | Превращает DAG в картинку (dot → PNG/SVG)


### 5.4. Проверяем CWLtool
```bash
conda activate cwl_env
which cwltool
cd ~/bioinf_hw3/cwl

nano test.cwl
```

Вставить:
```yaml
cwlVersion: v1.2
class: CommandLineTool

# Базовая команда
baseCommand: echo

# Входные параметры
inputs:
  message:
    type: string
    inputBinding:
      position: 1

# Выходные данные
outputs:
  printed_message:
    type: stdout

# Куда сохранить вывод
stdout: "test_cwl_output.txt"
```
* class: CommandLineTool — это отдельная команда (не workflow)
* baseCommand: echo — вызывает системную команду echo
* inputs  — описываем параметры, которые мы передадим
* outputs — забираем stdout в файл
* stdout  — перенаправляем вывод в файл

### Файлик с входными тестовыми данными
```bash
nano test_cwl_input.yml
```

Вставить:
```yaml
message: "Hello world! It's CWL workflow!"
```

### Запуск теста
```bash
cwltool test.cwl test_cwl_input.yml
```


## Этап 6. Пипелин (pipeline)
Пайплайн будет такой:
1) BWA mem  — создать `.sam`
2) SAM->BAM — получить `.bam` (сжатый бинарный)
3) Sort — `.sorted.bam`
4) Index — `.bai`
5) Flagstat — `.txt`
6) Parse — итоги

Пайплайн будет в папке `cwl`: `cd ~/bioinf_hw3/cwl`

### 1. BWA
```yaml
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
```

### 2. SAMtool
```yaml
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
```

### 3. BAM Sort
```yaml
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
```

### 4. BAM Index
```yaml
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
```

### 5. Flagstat
```yaml
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
```

### 6. Parse (итоги)
```yaml
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
```

### 7. Воедино! All-in-one
```yaml
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
```


### Входные данные и запуск
```yaml
# input_mapping.yml

reference:
  class: File
  path: ../ref/ecoli_ref.fna
  secondaryFiles:
    - class: File
      path: ../ref/ecoli_ref.fna.amb
    - class: File
      path: ../ref/ecoli_ref.fna.ann
    - class: File
      path: ../ref/ecoli_ref.fna.bwt
    - class: File
      path: ../ref/ecoli_ref.fna.pac
    - class: File
      path: ../ref/ecoli_ref.fna.sa

reads_R1:
  class: File
  path: ../data/SRR35085086_1.fastq.gz

reads_R2:
  class: File
  path: ../data/SRR35085086_2.fastq.gz

ok_threshold: 95
pot_threshold: 80
```

```bash
# Убеждаемся, что мы в окружении CWL
conda activate cwl_env
cd ~/bioinf_hw3/cwl

# Запуск (у меня занял минуты 3-4)
cwltool --outdir ../cwl_results mapping_workflow.cwl input_mapping.yml
cwltool --debug --outdir ../cwl_results mapping_workflow.cwl input_mapping.yml 2>&1 | tee ../cwl_results/pipeline_debug.log

# Или с выводом в консоль (без сохранения промежуточных файлов)
cwltool mapping_workflow.cwl input_mapping.yml
```

## Этап 7. Визуализация
```bash
cd ~/bioinf_hw3/cwl
conda activate cwl_env

cd ../cwl_results

# Создаём DOT файл
cwltool --print-dot ../cwl/mapping_workflow.cwl > workflow.dot

# Текстовое представление структуры
cat workflow.dot

# Конвертируем в PNG и/или SVG
dot -Tpng workflow.dot -o workflow.png
dot -Tsvg workflow.dot -o workflow.svg
```
