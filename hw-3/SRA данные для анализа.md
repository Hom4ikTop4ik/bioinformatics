# SRA данные для анализа

1) Зайти на `https://www.ncbi.nlm.nih.gov/sra`
2) Искать `Escherichia coli AND "illumina" AND "pair end" AND "wgs"`
3) Выбран SRX30198562 (он же SRR35085086)

- **Организм**: Escherichia coli
- **Тип секвенирования**: Whole Genome Sequencing (WGS), paired-end
- **Платформа**: Illumina
- **SRA Accession**: SRR35085086
- **Размер**: ~139 MB (сжатые FASTQ)
- **Количество ридов**: 965,201 пар


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