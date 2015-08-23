del = require 'del'
gulp = require 'gulp'
less = require 'gulp-less'
shell = require 'gulp-shell'
debug = require 'gulp-debug'
order = require 'gulp-order'
rsync = require 'gulp-rsync'
coffee = require 'gulp-coffee'
filter = require 'gulp-filter'
concat = require 'gulp-concat'
uglify = require 'gulp-uglify'
minifyCss = require 'gulp-minify-css'
bowerFiles = require 'main-bower-files'
runSequence = require 'run-sequence'
browserify = require 'browserify'
reactify = require 'reactify'
source = require 'vinyl-source-stream'
coffeeify = require 'coffeeify'

gulp.task 'clean', ->
  del 'public/*'

gulp.task 'vendor:bootstrap:styles', ->
  gulp.src 'core/view/styles/bootstrap.less'
  .pipe less
    paths: ['bower_components/bootstrap']
  .pipe minifyCss()
  .pipe gulp.dest 'public'

gulp.task 'scripts:admin', ->
  browserify 'core/view/admin/admin.coffee'
  .transform coffeeify
  .transform reactify, es6: true
  .bundle()
  .pipe source 'admin.js'
  .pipe gulp.dest 'public'

gulp.task 'styles:admin', ->
  gulp.src 'core/view/admin/admin.less'
  .pipe less()
  .pipe minifyCss()
  .pipe gulp.dest 'public'

gulp.task 'vendor:scripts', ->
  gulp.src bowerFiles()
  .pipe filter '*.js'
  .pipe order ['jquery.js', 'underscore.js', '*']
  .pipe concat 'vendor.js'
  .pipe uglify()
  .pipe gulp.dest 'public/vendor'

gulp.task 'vendor:fonts', ->
  gulp.src bowerFiles()
  .pipe filter ['*.eot', '*.svg', '*.ttf', '*.woff', '*.woff2']
  .pipe gulp.dest 'public'

gulp.task 'build:vendor', ['vendor:bootstrap:styles', 'vendor:scripts', 'vendor:fonts']

gulp.task 'build:styles', ->
  gulp.src 'core/public/style/*.less'
  .pipe less()
  .pipe concat 'core.css'
  # .pipe minifyCss()
  .pipe gulp.dest 'public'

gulp.task 'build:scripts', ->
  gulp.src 'core/public/script/*.coffee'
  .pipe coffee()
  .pipe order ['root.coffee', '*']
  .pipe concat 'core.js'
  # .pipe uglify()
  .pipe gulp.dest 'public'

gulp.task 'watch', ->
  gulp.watch 'core/public/style/*.less', ['build:styles']
  gulp.watch 'core/public/script/*.coffee', ['build:scripts']
  gulp.watch ['core/view/admin/*.jsx', 'core/view/admin/*.coffee'], ['scripts:admin']

gulp.task 'build', ['build:vendor', 'build:styles', 'build:scripts', 'scripts:admin', 'styles:admin']

gulp.task 'build:docs', shell.task 'node_modules/.bin/endokken --extension html --theme bullet --dest ./docs-public'

gulp.task 'deploy:docs', ['build:docs'], ->
  gulp.src 'docs-public/*'
  .pipe rsync
    root: 'docs-public',
    hostname: 'spawn.rpvhost.net',
    destination: '/home/jysperm/rootpanel/docs'
