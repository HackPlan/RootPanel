## SSH Plugin API

### POST /plugin/ssh/update_passwd/

Request:

    {
        "passwd": "123123"
    }

No Response.

Exception:

* invalid_passwd
* not_in_service
