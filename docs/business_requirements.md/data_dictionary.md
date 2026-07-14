# Data Dictionary - Retention Engine

## 1. Customers Source File
* `customer_id`: Unique token assigned per order transaction.
* `customer_unique_id`: Unique identifier tracking the specific customer account long-term (Essential for cohort analysis!).
* `customer_city` / `customer_state`: Geographic location fields.

## 2. Products Source File
* `product_id`: Alpha-numeric product serial string.
* `product_category_name`: Main classification tag.

## 3. Order Items Ledger File
* `order_id`: Structural identifier link for an invoice.
* `price`: Numeric item cost tracking purchase revenue values.