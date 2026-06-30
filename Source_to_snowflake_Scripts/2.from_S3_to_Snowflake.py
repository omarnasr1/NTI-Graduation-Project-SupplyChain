import snowflake.connector
import os
from dotenv import load_dotenv
load_dotenv()

conn = snowflake.connector.connect(
    user= os.environ.get("snowflake_user"),
    password= os.environ.get("snowflake_password"),
    account= os.environ.get("snowflake_account"),
    warehouse= os.environ.get("snowflake_warehouse"),
    database= os.environ.get("snowflake_database"),
    schema= os.environ.get("snowflake_schema")
)

cs = conn.cursor()


sql_create_table_query = """
CREATE OR REPLACE TABLE raw_supplyChain (
    Type                              STRING,
    Days_for_shipping_real            INTEGER,
    Days_for_shipment_scheduled       INTEGER,
    Benefit_per_order                 DOUBLE,
    Sales_per_customer                DOUBLE,
    Delivery_Status                   STRING,
    Late_delivery_risk                INTEGER,
    Category_Id                       INTEGER,
    Category_Name                     STRING,
    Customer_City                     STRING,
    Customer_Country                  STRING,
    Customer_Email                    STRING,
    Customer_Fname                    STRING,
    Customer_Id                       INTEGER,
    Customer_Lname                    STRING,
    Customer_Password                 STRING,
    Customer_Segment                  STRING,
    Customer_State                    STRING,
    Customer_Street                   STRING,
    Customer_Zipcode                  INTEGER,
    Department_Id                     INTEGER,
    Department_Name                   STRING,
    Latitude                          DOUBLE,
    Longitude                         DOUBLE,
    Market                            STRING,
    Order_City                        STRING,
    Order_Country                     STRING,
    Order_Customer_Id                 INTEGER,
    Order_Date                        STRING,
    Order_Id                          INTEGER,
    Order_Item_Cardprod_Id            INTEGER,
    Order_Item_Discount               DOUBLE,
    Order_Item_Discount_Rate          DOUBLE,
    Order_Item_Id                     INTEGER,
    Order_Item_Product_Price          DOUBLE,
    Order_Item_Profit_Ratio           DOUBLE,
    Order_Item_Quantity               INTEGER,
    Sales                             DOUBLE,
    Order_Item_Total                  DOUBLE,
    Order_Profit_Per_Order            DOUBLE,
    Order_Region                      STRING,
    Order_State                       STRING,
    Order_Status                      STRING,
    Order_Zipcode                     INTEGER,
    Product_Card_Id                   INTEGER,
    Product_Category_Id               INTEGER,
    Product_Description               STRING,
    Product_Image                     STRING,
    Product_Name                      STRING,
    Product_Price                     DOUBLE,
    Product_Status                    INTEGER,
    Shipping_Date                     STRING,
    Shipping_Mode                     STRING,
    Movement_Date                     STRING,
    Quantity_Moved                    INTEGER,
    Unit_Cost_At_Movement             DOUBLE,
    Stock_On_Hand_After_Movement      INTEGER,
    Movement_Type_Name                STRING,
    Movement_Direction                STRING,
    Warehouse_Name                    STRING,
    Warehouse_Type                    STRING,
    Warehouse_City                    STRING,
    Warehouse_Country                 STRING,
    Warehouse_Capacity                INTEGER
);
"""

cs.execute(sql_create_table_query)
print("Table raw_supplyChain created.")


aws_access_key = os.environ.get("AWS_ACCESS_KEY_ID")
aws_secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
region_name = os.environ.get("AWS_REGION")
bucket_name = os.environ.get("AWS_S3_BUCKET_NAME")
s3_key = os.environ.get("AWS_S3_KEY")

cs.execute("""
CREATE OR REPLACE FILE FORMAT my_csv_format
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
""")

cs.execute(f"""
CREATE OR REPLACE STAGE my_s3_stage
    URL = 's3://{bucket_name}/SupplyChain/'
    CREDENTIALS = (AWS_KEY_ID = '{aws_access_key}' AWS_SECRET_KEY = '{aws_secret_key}')
    FILE_FORMAT = my_csv_format
""")

print("File format and stage created.")


copy_sql = """
COPY INTO raw_supplyChain
FROM @my_s3_stage/DataCoSupplyChainDataset.csv
FILE_FORMAT = (FORMAT_NAME = my_csv_format)
ON_ERROR = 'CONTINUE'
"""

cs.execute(copy_sql)
result = cs.fetchall()
print("Load result:", result)

cs.execute("SELECT COUNT(*) FROM raw_supplyChain")
print("Row count:", cs.fetchone()[0])

cs.close()
conn.close()