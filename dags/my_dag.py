from airflow.sdk import dag
from datetime import datetime

from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.bash import BashOperator

from include.scripts.check_raw_SupplyChain import check_row_count


DBT_PROJECT_PATH = "/usr/local/airflow/dbt/SupplyChainDBT"


@dag(
    start_date=datetime(2026, 6, 1),
    schedule=None,
    catchup=False,
)
def my_dag():

   

    check_count = PythonOperator(
        task_id="check_row_count",
        python_callable=check_row_count,
    )

    dbt_staging_run = BashOperator(
        task_id="dbt_staging_run",
        bash_command=(
            f"cd {DBT_PROJECT_PATH} && "
            "dbt run --select path:models/staging --profiles-dir ."
        ),
    )

    dbt_staging_test = BashOperator(
        task_id="dbt_staging_test",
        bash_command=(
            f"cd {DBT_PROJECT_PATH} && "
            "dbt test --select path:models/staging --profiles-dir ."
        ),
    )

    dbt_DWH_run = BashOperator(
        task_id="dbt_DWH_run",
        bash_command=(
            f"cd {DBT_PROJECT_PATH} && "
            "dbt run --select path:models/DWH --profiles-dir ."
        ),
    )

    dbt_DWH_test = BashOperator(
        task_id="dbt_DWH_test",
        bash_command=(
            f"cd {DBT_PROJECT_PATH} && "
            "dbt test --select path:models/DWH --profiles-dir ."
        ),
    )

    check_count >> dbt_staging_run >> dbt_staging_test >> dbt_DWH_run >> dbt_DWH_test


my_dag()