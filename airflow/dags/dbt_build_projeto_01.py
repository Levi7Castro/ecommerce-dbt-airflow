from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

DBT_BIN = "/opt/airflow/dbt_venv/bin/dbt"
DBT_PROJECT_DIR = "/opt/airflow/dbt/projeto_01"
DBT_PROFILES_DIR = "/opt/airflow/dbt_profiles"

DBT_ARGS = f"--project-dir {DBT_PROJECT_DIR} --profiles-dir {DBT_PROFILES_DIR}"

with DAG(
    dag_id="dbt_build_projeto_01",
    description="Roda o dbt build do projeto_01 (seeds, bronze, silver, gold e testes)",
    start_date=datetime(2026, 10, 1),
    schedule="@daily",
    catchup=False,
    default_args={
        "retries": 1,
        "retry_delay": timedelta(minutes=2),
    },
    tags=["dbt", "projeto_01"],
) as dag:

    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=f"{DBT_BIN} debug {DBT_ARGS}",
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"{DBT_BIN} build {DBT_ARGS}",
    )

    dbt_debug >> dbt_build
