## 插件编写指南

### 概览
插件分为两种类型：

* 服务 (service)

    用于为 RootPanel 添加一项服务，服务往往需要开通才能使用，如一种新的数据库支持。

* 拓展 (extension)

    用于提供功能性的扩展，拓展通常面向所有用户，如添加一种支付方式。

插件需要被安装到 RootPanel 下的 `plugin` 目录，每个目录即为一个插件。插件需要在 `config.coffee` 中被开启才会被加载：

    plugin:
      available_extensions: ['rpvhost', 'bitcoin', 'wiki']
      available_services: ['ssh', 'linux']

### 插件结构
插件的入口点是插件目录下的 `index.coffee`, 通常建议该文件用于注册 hook, 而将插件的逻辑置于单独的文件。

插件目录下有一些目录是具有特殊用途的：

* locale: 本地化翻译数据

    其中每个文件表示一种语言支持，需以 `zh_CN.json` 的形式命名。

* static: 静态资源

    该目录会被挂载到 `/plugin/<name>/`.

* test: 单元测试

    直接位于该目录下的 .coffee 文件会参与单元测试。

* view: 页面模板

    该目录下的 .jade 文件可以直接被 plugin.render 调用。

* template: 文件模板

    该目录下的文件可以直接被 plugin.renderFile 调用。

### 插件入口点
插件的入口点文件 `index.coffee` 必须通过 `pluggable.createHelpers` 导出下列格式的插件信息：

    module.exports = pluggable.createHelpers exports =
      name: 'ssh'
      type: 'service'
      dependencies: ['linux']

* name

    插件的唯一标识。

* type

    `service` 或 `extension`.

* dependencies

    该插件依赖的其他插件，如果依赖条件不满足，会产生一个错误。

### 注册钩子
插件通过 `pluggable.registerHook` 注册钩子，来与主程序交互。

所有钩子的列表可在 `/core/pluggable.coffee` 中找到，其中标注了每个钩子的选项和参数。

选项位于 hookHelper 后：

* global_event

    表示这个钩子会通知所有插件，即使这个用户未开通这个 service, 通常这类钩子与具体用户无关。

参数是注册钩子时需要提供的信息，以注释标注：

* callback

    在钩子执行结束后，插件需要调用 callback.

* action

    表示这个函数会被钩子执行。

* filter

    表示这个函数会被钩子执行，而且通常该函数的结果会影响后续执行，或者建议在这个函数中修改传入的数据。

* generator

    表示这个函数用于生成一段 HTML.

* path

    表示这是一个会用于前端，表示路径的字符串。

除了与具体 Hook 相关的参数，还有一些适用于所有钩子的参数：

* always_notice

    作用同 global_event, 要求即使这个用户未开通这个 service 也被调用。

### 创建钩子
插件也可以通过 `pluggable.createHookPoint` 来创建一个钩子的挂载点，来允许其他插件注册钩子。

在执行钩子时，可通过 `pluggable.selectHook` 来提取其他插件注册的钩子。

### Helpers
`pluggable.createHelpers` 在创建插件信息的时候会创建一些辅助函数：

* registerHook

    `pluggable.registerHook` 的缩写形式。

* registerServiceHook

    用 `pluggable.registerHook` 创建 service 类钩子的缩写形式。

* t

    返回一个翻译器，用于从插件的 locale 目录提取翻译信息。

* render

    渲染插件的 view 目录下的页面模板。

* renderFile

    渲染插件的 template 目录下的模板。

### app
`app` 是一个全局变量，RootPanel 运行中的所有信息都挂载在这个全局变量上，插件可以从上面得到需要的资源：

* libs

    包括被引入的所有 Node Package.

* logger

    用于打印日志，代替 `console.log`.

* config, package

    配置文件和 `package.json`

* express, redis, mailer, db

    `express`, `redis`, `nodemailer`, `mongoose` 的实例

* models, schemas

    Model 和 Schema, 注意在插件的入口点文件被载入时，Model 还没有被创建好，因此不要在入口点文件中直接读取 `models` 中的 Model.

* templates, i18n, utils, cache, billing, pluggable, middleware, notification, authenticator

    RootPanel 的其他组成部分
