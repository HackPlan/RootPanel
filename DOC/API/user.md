## User API

### POST /user/signup/

Request:

    {
      "username": "jysperm",
      "passwd": "password"
    }

Response:

    {
      "id": "525284cc2cebb6d0008b4567"
    }

Exception:

* username_exist
* invalid_username
* invalid_passwd

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
