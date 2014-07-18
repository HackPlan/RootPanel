## Admin API

### POST /admin/create_payment/

Request:

    {
        "account_id": "525284cc2cebb6d0008b4567",
        "type": "taobao",
        "amount": 10,
        "order_id": "560097131641814"
    }

Exception:

* account_not_exist
* invalid_amount
