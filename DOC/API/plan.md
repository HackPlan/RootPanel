## Plan API

### POST /plan/subscribe/

Request:

    {
        "plan": "shadowsocks"
    }

No Response.

Exception:

* invaild_plan
* already_in_plan
* insufficient_balance

### POST /plan/unsubscribe/

Request:

    {
        "plan": "shadowsocks"
    }

No Response.
