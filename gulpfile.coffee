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

gulp.task 'clean', ->
  del 'public/*'

gulp.task 'vendor:styles', ->
  gulp.src bowerFiles()
  .pipe filter '*.less'
  .pipe less()
  .pipe concat 'vendor.css'
  .pipe minifyCss()
  .pipe gulp.dest 'public/vendor'

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
  .pipe gulp.dest 'public/fonts'

gulp.task 'build:vendor', ->
  runSequence [
    'clean'
  ], [
    'vendor:styles'
    'vendor:scripts'
    'vendor:fonts'
  ]

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

gulp.task 'build', ['build:vendor', 'build:styles', 'build:scripts']

gulp.task 'build:docs', shell.task 'node_modules/.bin/endokken --extension html --theme bullet --dest ./docs-public'

gulp.task 'deploy:docs', ['build:docs'], ->
  gulp.src 'docs-public/*'
  .pipe rsync
    root: 'docs-public',
    hostname: 'spawn.rpvhost.net',
    destination: '/home/jysperm/rootpanel/docs'
