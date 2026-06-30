# consumer.py
import json
import os

import pandas as pd
from confluent_kafka import Consumer

from s3_utils import upload_to_s3
from snowflake_loader import load_file


COLUMNS = [
    "Type",
    "Days_for_shipping_real",
    "Days_for_shipment_scheduled",
    "Benefit_per_order",
    "Sales_per_customer",
    "Delivery_Status",
    "Late_delivery_risk",
    "Category_Id",
    "Category_Name",
    "Customer_City",
    "Customer_Country",
    "Customer_Email",
    "Customer_Fname",
    "Customer_Id",
    "Customer_Lname",
    "Customer_Password",
    "Customer_Segment",
    "Customer_State",
    "Customer_Street",
    "Customer_Zipcode",
    "Department_Id",
    "Department_Name",
    "Latitude",
    "Longitude",
    "Market",
    "Order_City",
    "Order_Country",
    "Order_Customer_Id",
    "Order_Date",
    "Order_Id",
    "Order_Item_Cardprod_Id",
    "Order_Item_Discount",
    "Order_Item_Discount_Rate",
    "Order_Item_Id",
    "Order_Item_Product_Price",
    "Order_Item_Profit_Ratio",
    "Order_Item_Quantity",
    "Sales",
    "Order_Item_Total",
    "Order_Profit_Per_Order",
    "Order_Region",
    "Order_State",
    "Order_Status",
    "Order_Zipcode",
    "Product_Card_Id",
    "Product_Category_Id",
    "Product_Description",
    "Product_Image",
    "Product_Name",
    "Product_Price",
    "Product_Status",
    "Shipping_Date",
    "Shipping_Mode",
    "Movement_Date",
    "Quantity_Moved",
    "Unit_Cost_At_Movement",
    "Stock_On_Hand_After_Movement",
    "Movement_Type_Name",
    "Movement_Direction",
    "Warehouse_Name",
    "Warehouse_Type",
    "Warehouse_City",
    "Warehouse_Country",
    "Warehouse_Capacity"
]

BUCKET_NAME = "raw-supplychain-data"


consumer_config = {
    "bootstrap.servers": "localhost:9092",
    "group.id": "order-tracker",
    "auto.offset.reset": "latest"
}


consumer = Consumer(consumer_config)

consumer.subscribe(["orders"])

print("Consumer started")


try:

    while True:

        msg = consumer.poll(1.0)

        if msg is None:
            continue

        if msg.error():
            print(msg.error())
            continue

        order = json.loads(
            msg.value().decode("utf-8")
        )

        order_item_id = order["Order_Item_Id"]

        filename = f"order_{order_item_id}.csv"

        row = {col: order.get(col) for col in COLUMNS}

        df = pd.DataFrame([row], columns=COLUMNS)

        df.to_csv(
            filename,
            index=False
        )

        print(f"CSV created: {filename}")
        # some notes
        upload_to_s3(
            filename,
            BUCKET_NAME,
            f"SupplyChain/{filename}"
        )

        load_file(filename)

        os.remove(filename)

        print(f"🗑️ Deleted local file: {filename}")


except KeyboardInterrupt:

    consumer.close()
