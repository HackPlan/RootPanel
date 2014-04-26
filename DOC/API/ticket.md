## Ticket API

### POST /ticket/create/

Request:

    {
        "title": "Ticket Title",
        "content": "Ticket Content(Markdown)",
        "type": "linux",

        // only for admin group user
        "members": [
            "jysperm", "jysperm@gmail.com"
        ]
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567"
    }

Exception:

* invalid_title `/^.+$/`
* invalid_type
* invalid_account: username

### POST /ticket/reply/

Request:

    {
        "id": "525284cc2cebb6d0008b4567"
        "content": "Reply Content(Markdown)"
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567"
    }

Exception:

* ticket_not_exist
* forbidden

### POST /ticket/update/

Request:

    {
        "id": "525284cc2cebb6d0008b4567",
        // optional
        "type": "linux",
        // optional
        "status": "closed",

        // only for admin group user
        "attribute": {
            "public": true
        },
        "members": {
            // add a user
            "525284cc2cebb6d0008b4567": true,
            // remove a user
            "4cc2cebb6d5254567280008b": false
        }
    }

No Response.

Exception:

* invalid_type
* already_in_status
* invalid_status

### POST /ticket/list/

Request:

    {
        "type": "linux",
        "status": "open/pending/finish/closed",
        "limit": 30,
        "skip": 0
    }

Response:

    [
        {
            "id": "525284cc2cebb6d0008b4567",
            "title": "Ticket Title",
            "type": "linux",
            "status": "open",
            "updated_at": "2014-02-18T09:18:27.214Z"
        }
    ]
