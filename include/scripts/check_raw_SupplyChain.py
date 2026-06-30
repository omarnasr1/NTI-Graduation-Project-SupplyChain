from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

def check_row_count():

    hook = SnowflakeHook(
        snowflake_conn_id="snowflake_conn"
    )

    result = hook.get_first("""
        SELECT COUNT(*)
        FROM RAW_SUPPLYCHAIN
    """)

    row_count = result[0]

    print(f"Number of Rows = {row_count}")

    if row_count == 0:
        raise ValueError("RAW_SUPPLYCHAIN table is empty")

    print("RAW_SUPPLYCHAIN contains data")