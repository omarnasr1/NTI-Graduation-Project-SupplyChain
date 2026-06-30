# snowflake_loader.py
import snowflake.connector


conn = snowflake.connector.connect(
    user="3mar7nasr",
    password="JCqdm571omaromar",
    account="rm96122.af-south-1.aws",
    warehouse="supplyChain_wh",
    database="SupplyChain_db",
    schema="raw"
)


def load_file(filename):

    cursor = conn.cursor()

    sql = f"""
    COPY INTO raw_supplyChain
    FROM @my_pycharm_s3_stage/{filename}
    FILE_FORMAT = (
        TYPE = CSV
        FIELD_OPTIONALLY_ENCLOSED_BY='"'
        SKIP_HEADER=1
    );
    """

    cursor.execute(sql)

    print(f"✅ Loaded {filename} into Snowflake")

    cursor.close()