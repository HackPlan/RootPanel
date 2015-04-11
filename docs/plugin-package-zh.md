RootPanel 的每个插件都是一个 Node.js 包，拥有一个 `package.json`, 包含下列字段：

* name
* auhtor
* version
* homepage
* repository
* description
* dependencies
* devDependencies

`dependencies` 字段中定义的依赖会在运行 `npm run install-plugins` 时被安装。
