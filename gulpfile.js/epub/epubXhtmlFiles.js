var gulp = require('gulp'),
    debug = require('gulp-debug'),
    rename = require('gulp-rename'),
    paths = require('../paths.js');

// Rename epub .html files to .xhtml.
// Creates a copy of the file that must then be cleaned out
// with the subsequent gulp task `epub:cleanHtmlFiles``
gulp.task('epubXhtmlFiles', function (done) {
    'use strict';

    console.log('Renaming *.html to *.xhtml in ' + paths.epub.src);
    gulp.src(paths.epub.src)
        .pipe(debug({title: 'Renaming '}))
        .pipe(rename({
            extname: '.xhtml'
        }))
        .pipe(gulp.dest(paths.epub.dest));
    done();
});
