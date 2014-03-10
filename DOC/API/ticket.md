## Ticket API

### POST /ticket/create

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

### POST /ticket/reply

Request:

    {
        "id": "525284cc2cebb6d0008b4567"
        "reply_to": "525284cc2cebb6d0008b4567",
        "content": "Reply Content(Markdown)"
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567"
    }

### POST /ticket/update

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
