var gulp = require('gulp'),
    paths = require('./paths.js'),
    uglify = require('gulp-uglify');

// Minify JS files to make them smaller,
// using the drop_console option to remove console logging
gulp.task('js', function (done) {
    'use strict';

    if (paths.js.src.length > 0) {
        console.log('Minifying Javascript');
        gulp.src(paths.js.src)
            .pipe(debug({title: 'Minifying '}))
            .pipe(uglify({compress: {drop_console: true}}).on('error', function (e) {
                console.log(e);
            }))
            .pipe(rename({suffix: '.min'}))
            .pipe(gulp.dest(paths.js.dest));
        done();
    } else {
        console.log('No scripts in source list to minify.');
        done();
    }
});
