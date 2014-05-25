## MySQL Plugin API

### POST /plugin/mysql/update_passwd/

Request:

    {
        "passwd": "123123"
    }

No Response.

Exception:

* invalid_passwd
* not_in_service
