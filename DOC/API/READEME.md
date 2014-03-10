## API 格式

请求和响应均为 `application/json` 格式。

修改性的请求为 POST 方式，非修改性请求 GET/POST 均可，使用 GET 方式时，用 Query String 来传递参数。

响应代码为 200 表示成功，400 表示失败。成功会返回特定的数据，失败的响应会包含错误代号：

    {
        // 错误代号
        "error": "username_exist"
        // 根据错误代号不同，可能还有更多字段
    }

## 登录验证

登录验证可通过 Cookie 和 HTTP Header 两种方式验证，后者优先级更高。
Cookie 字段名为 `token`, HTTP Header 名为 `X-TOKEN`.
验证失败时会发生 `auth_failed` 错误。
