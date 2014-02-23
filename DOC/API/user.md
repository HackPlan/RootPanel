## User API

### POST /user/signup/

Request:

    {
        "username": "jysperm",
        "email": "jysperm@gmail.com"
        "passwd": "password"
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567"
    }

Exception:

* username_exist
* email_exist
* invalid_username `/^[0-9a-z_]+$/`
* invalid_email `/^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$/`
* invalid_passwd `/^.+$/`

### POST /user/login/

Request:

    {
        "username": "jysperm",
        "passwd": "passwd"
    }

Response:

    {
        "id": "525284cc2cebb6d0008b4567",
        "token": "b535a6cec7b73a60c53673f434686e04972ccafddb2a5477f066f30eded55a9b"
    }

Exception:

* auth_failed
