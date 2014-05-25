## Nginx Plugin API

### POST /plugin/nginx/update_site/

Request:

    {
        "type": "guide/json/nginx",
        "config": <Object>
    }

No Response.

Exception:

* not_in_service
