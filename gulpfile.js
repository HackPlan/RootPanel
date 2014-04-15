var gulp = require('gulp');
var less = require('gulp-less');
var coffee = require('gulp-coffee');
var uglify = require('gulp-uglify');
var path = require('path');


gulp.task('less', function() {
  return gulp.src(['./**/*.less','!node_modules/**/*.less']).pipe(less()).pipe(gulp.dest('./'));
});

gulp.task('coffee', function() {
  return gulp.src(['./**/*.coffee','!node_modules/**/*.coffee']).pipe(coffee({bare:true})).on('error', function(error) {
    throw error;
  }).pipe(uglify()).pipe(gulp.dest('./'));
});

gulp.task('watch', function(){
  gulp.watch([ './**/*.coffee','!node_modules/**/*.coffee'],['coffee']);
  gulp.watch(['./**/*.less','!node_modules/**/*.less'],['less']);
});

gulp.task('default', ['less', 'coffee', 'watch']);
