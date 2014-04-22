## API 格式

请求和响应均为 `application/json` 格式，大部分 API 均为 POST 方式。

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

## 分页
limit 和 skip 参数用于分页，limit 表示要返回的结果数量，skip 表示跳过前若干条结果，limit 默认为 30, skip 默认为 0.
