## MySQL Plugin API

### POST /plugin/mysql/update_password/

Request:

    {
        "password": "123123"
    }

No Response.

Exception:

* invalid_password
* not_in_service
