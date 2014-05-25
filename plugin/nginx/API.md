## Nginx Plugin API

### POST /plugin/nginx/update_site/

Request:

    {
        "action": "create/update/delete",
        // only when update
        "id": "525284cc2cebb6d0008b4567",
        "type": "guide/json/nginx",
        "config": <Object>
    }

No Response.

Exception:

* not_in_service
