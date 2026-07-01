# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

pip install requests pytz azure-servicebus

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import requests

try:
    response = requests.get(
        f"https://supply-chain-api-qate.onrender.com/api/v1/orders/pending?limit=100",
        timeout=15
    )

    response.raise_for_status()

    orders = response.json().get("orders", [])

    if not orders:
        print(None)

    print(orders[-1])

except requests.exceptions.RequestException as e:
    print(f"❌ API request failed: {e}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark",
# META   "frozen": false,
# META   "editable": true
# META }

# CELL ********************

import json
import time
import requests
from azure.servicebus import ServiceBusClient, ServiceBusMessage

myconnectionstring = "Endpoint=sb://esehparaflszb2xpejzrblw.servicebus.windows.net/;SharedAccessKeyName=key_062d81cd-f40c-4baf-b091-e43040f11085;SharedAccessKey=X5FZQfyDv76Iu/5IgBjd6igndZ3YjXdOl+AEhIJ+3pM=;EntityPath=esehparaflszb2xpejzrblw_eh"

API_URL = "https://supply-chain-api-qate.onrender.com/api/v1/orders/pending"
POLL_INTERVAL_SECONDS = 10


def get_entity_path(connection_string):
    for param in connection_string.split(';'):
        if param.startswith('EntityPath='):
            return param.split('=')[1]
    raise ValueError("EntityPath is missing in the connection string. Please check your Fabric setup.")


def fetch_order():
    """Fetch the single most recent pending order from the API."""
    try:
        response = requests.get(API_URL, params={"limit": 100}, timeout=15)
        response.raise_for_status()
        orders = response.json().get("orders", [])

        if not orders:
            return None

        return orders[-1]

    except requests.exceptions.RequestException as e:
        print(f"❌ API request failed: {e}")
        return None


def send_to_eventstream(order, entity_path, servicebus_client):
    try:
        with servicebus_client.get_queue_sender(entity_path) as sender:
            message = ServiceBusMessage(json.dumps(order))
            sender.send_messages(message)
            print(f"✅ Delivered Order {order.get('Order_Item_Id')}")
    except Exception as e:
        print(f"❌ Delivery failed: {e}")


# -------------------------
# Initialize last order ID
# -------------------------
entity_path = get_entity_path(myconnectionstring)
servicebus_client = ServiceBusClient.from_connection_string(myconnectionstring)

last_order = fetch_order()

if last_order:
    last_sent_order_item_id = last_order.get("Order_Item_Id")
    print(
        f"🟢 Producer started. "
        f"Current latest order is {last_sent_order_item_id}. "
        f"Waiting for new orders..."
    )
else:
    last_sent_order_item_id = None
    print("🟢 Producer started. No existing orders found.")


# -------------------------
# Main loop
# -------------------------
try:
    while True:
        order = fetch_order()

        if order:
            current_order_item_id = order.get("Order_Item_Id")

            if current_order_item_id != last_sent_order_item_id:
                send_to_eventstream(order, entity_path, servicebus_client)
                last_sent_order_item_id = current_order_item_id
                print(f"📦 New order detected: {current_order_item_id}")

        time.sleep(POLL_INTERVAL_SECONDS)

except KeyboardInterrupt:
    print("\n🛑 Producer stopped by user.")

finally:
    servicebus_client.close()
    print("✅ EventStream connection closed successfully.")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
