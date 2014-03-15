## User API

### POST /account/signup/

Request:

    {
        "username": "jysperm",
        "email": "jysperm@gmail.com",
        "passwd": "passwd"
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567"
    }

Response Header:

    Set-Cookie: token=b535a6cec7b73a60c53673f434686e04972ccafddb2a5477f066f30eded55a9b

Exception:

* username_exist
* email_exist
* invalid_username `/^[0-9a-z_]+$/`
* invalid_email `/^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/`
* invalid_passwd `/^.+$/`

### POST /account/login/

Request:

    {
        // username or email
        "username": "jysperm",
        "passwd": "passwd"
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567",
        "token": "b535a6cec7b73a60c53673f434686e04972ccafddb2a5477f066f30eded55a9b"
    }

Response Header:

    Set-Cookie: token=b535a6cec7b73a60c53673f434686e04972ccafddb2a5477f066f30eded55a9b

Exception:

* auth_failed

### POST /account/logout/

No Request.

No Response.

Response Header:

    Set-Cookie: token=deleted

Exception:

* auth_failed
