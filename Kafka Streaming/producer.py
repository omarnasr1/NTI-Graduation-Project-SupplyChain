# producer.py
import json
import time
import requests
from confluent_kafka import Producer

POLL_INTERVAL_SECONDS = 10

producer = Producer({
    "bootstrap.servers": "localhost:9092"
})

def delivery_report(err, msg):
    if err:
        print(f"Delivery failed: {err}")
    else:
        print(f"Delivered Order {msg.offset()}")


def fetch_order():
    try:
        response = requests.get(
            f"https://supply-chain-api-qate.onrender.com/api/v1/orders/pending?limit=100",
            timeout=15
        )

        response.raise_for_status()

        orders = response.json().get("orders", [])

        if not orders:
            return None

        return orders[-1]

    except requests.exceptions.RequestException as e:
        print(f"API request failed: {e}")
        return None


# -------------------------
# Initialize last order ID
# -------------------------
last_order = fetch_order()

if last_order:
    last_sent_Order_Item_Id = last_order.get("Order_Item_Id")
    print(
        f"Producer started. "
        f"Current latest order is {last_sent_Order_Item_Id}. "
        f"Waiting for new orders..."
    )
else:
    last_sent_Order_Item_Id = None
    print("Producer started. No existing orders found.")


# -------------------------
# Main loop
# -------------------------
try:

    while True:

        order = fetch_order()

        if order:

            current_order_item_id = order.get("Order_Item_Id")

            if current_order_item_id != last_sent_Order_Item_Id:

                producer.produce(
                    "orders",
                    json.dumps(order).encode("utf-8"),
                    callback=delivery_report
                )

                producer.flush()

                last_sent_Order_Item_Id = current_order_item_id

                print(f"New order detected: {current_order_item_id}")

        time.sleep(POLL_INTERVAL_SECONDS)

except KeyboardInterrupt:

    print("\nProducer stopped by user.")

finally:

    producer.flush()

    print("Kafka producer closed successfully.")
