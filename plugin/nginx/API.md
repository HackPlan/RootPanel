## Nginx Plugin API

### GET /plugin/nginx/site_config

Request:

    {
        "id": "53c96734c2dad7d6208a0fbe"
    }
    
Response:

    {
        "id": "53c96734c2dad7d6208a0fbe",
        "listen": 80,
        "server_name": ["domain1.com", "domain2.net"],
        "auto_index": false,
        "index": ["index.html"],
        "root": "/home/user/web",
        "location": {
            "/": {
                "fastcgi_pass": "unix:///home/user/phpfpm.sock",
                "fastcgi_index": ["index.php"]
            }
        }
    }

### POST /plugin/nginx/update_site

Request:

    {
        "action": "create/update/delete",
        // only when update and delete
        "id": "525284cc2cebb6d0008b4567",
        "type": "guide/json/nginx",
        "config": <Object>
    }

No Response.

Exception:

* not_in_service
* invalid_action
* invalid_type
* forbidden

* invalid_listen
* invalid_server_name
* invalid_index
* invalid_root
* invalid_location
* invalid_fastcgi_index
* invalid_fastcgi_pass
