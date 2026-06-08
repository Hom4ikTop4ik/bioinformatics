# Инструкция по скачиванию и установке CWL (Common Workflow Language)
## Установка в WSL / Linux (Ubuntu/Debian)
### 1. Установка Miniconda (если ещё нет)
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3
~/miniconda3/bin/conda init bash
source ~/.bashrc
```

### 2. Создание отдельного окружения для CWL
```bash
conda create -n cwl_env python=3.9 -y
conda activate cwl_env
```

### 3. Установка cwltool (CWL runner)
**Через conda (рекомендуется):**
```bash
conda install -c conda-forge cwltool schema-salad -y
```

**Или через pip (альтернатива):**
```bash
pip install cwltool
```

### 4. Установка Graphviz (для визуализации DAG)
```bash
sudo apt update
sudo apt install -y graphviz
```

### 5. Проверка установки
```bash
cwltool --version
# Пример вывода: cwltool 3.1.20250715140722 (версия может отличаться)

dot -V
# Пример вывода: dot - graphviz version 14.1.2
```

---

## Что установлено

| Компонент      | Назначение |
|----------------|------------|
| `cwltool`      | Запуск CWL-пайплайнов (runner) |
| `schema-salad` | Проверка синтаксиса CWL-файлов |
| `graphviz`     | Преобразование DOT в PNG/SVG для визуализации |

---

## Тест "Hello World"

**Создаём файл `hello.cwl`:**
```yaml
cwlVersion: v1.2
class: CommandLineTool
baseCommand: echo
inputs:
  message:
    type: string
    inputBinding:
      position: 1
outputs:
  output:
    type: stdout
stdout: output.txt
```

**Создаём файл `hello.yml`:**
```yaml
message: "CWL is working!"
```

**Запускаем:**
```bash
conda activate cwl_env
cwltool hello.cwl hello.yml
cat output.txt
```

**Ожидаемый вывод:** `CWL is working!`

---

## Мои примечания под WSL
**Если conda не найдена после перезапуска:**
```bash
source ~/.bashrc
```
**При ошибках с сетью (в частности с DNS при установке через pip)** использовать `conda` вместо `pip`
