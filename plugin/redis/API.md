## Redis Plugin API

### POST /plugin/redis/switch

Request:

    {
        "enable": true
    }

No Response.

Exception:

* not_in_service
* invalid_enable
