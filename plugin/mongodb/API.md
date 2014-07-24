## MongoDB Plugin API

### POST /plugin/mongodb/update_password

Request:

    {
        "password": "123123"
    }

No Response.

Exception:

* invalid_password
* not_in_service

### POST /plugin/mongodb/create_database

Request:

    {
        "name": "jysperm_test"
    }
    
Exception:

* invalid_name

### POST /plugin/mongodb/delete_database

Request:

    {
        "name": "jysperm_test"
    }
    
Exception:

* invalid_name
