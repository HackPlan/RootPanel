gulp = require 'gulp'
less = require 'gulp-less'
coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'

path = require 'path'

lessPath = './core/static/style'
coffeePath = './core/static/script'

gulp.task 'less', ->
  gulp.src "#{lessPath}/**/*.less"
      .pipe less()
      .pipe gulp.dest(lessPath)


gulp.task 'coffee', ->
  gulp.src "#{coffeePath}/**/*.coffee"
      .pipe coffee()
      .on 'error', (error) ->
        throw error
      .pipe uglify()
      .pipe gulp.dest(coffeePath)


gulp.task 'default', ['less', 'coffee'], ->
  gulp.watch "#{lessPath}/**/*.less", ->
    gulp.run 'less'
  gulp.watch "#{coffeePath}/**/*.coffee", ->
    gulp.run 'coffee'
