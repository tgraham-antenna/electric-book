var gulp = require('gulp'),
    del = require('del'),
    paths = require('../paths.js');

// Clean out renamed .html files
gulp.task('epubCleanHtmlFiles', function () {
    'use strict';
    console.log('Removing old *.html files in ' + paths.epub.src);
    return del(paths.epub.src);
});
