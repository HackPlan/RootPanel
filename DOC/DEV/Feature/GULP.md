## gulp配置

执行所有操作前将gulpfile.coffee编译成gulpfile.js

### less

    gulp less

将static下的less编译成css到所在目录


### coffee

    gulp coffee
将static下的coffee编译并压缩到所在目录，如果有错误会throw，


### default

    gulp
执行上面两个操作，并watchstatic下的less和coffee文件
