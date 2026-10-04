FROM apache/airflow:3.3.0

# dbt fica num venv separado para não conflitar com as dependências do Airflow
RUN python -m venv /opt/airflow/dbt_venv \
    && /opt/airflow/dbt_venv/bin/pip install --no-cache-dir \
        dbt-core==1.12.5 \
        dbt-postgres==1.11.0
