# Business Architecture

## ER diagram for the workflow

![image](https://github.com/user-attachments/assets/7e3feb42-b7d3-4dce-899b-c56eec999387)

## Data pipeline flow

![image](https://github.com/user-attachments/assets/17c776d1-8d13-47c0-b502-e61b412070a8)

# Technical Architecture

```mermaid
flowchart TB
    dev([Developer]) -->|HTTPS :8080 UI| web

    subgraph azure [Azure Cloud]
        subgraph vm [Airflow VM - Docker Compose]
            web[Webserver UI]
            sched[Scheduler]
            worker[Worker - LocalExecutor]
        end
        pg[(Azure PostgreSQL<br/>metadata DB)]
        blob[/Azure Blob Storage<br/>DAG files + logs/]
    end

    vm -->|task runs, state| pg
    vm -->|read DAGs, write logs| blob
```
