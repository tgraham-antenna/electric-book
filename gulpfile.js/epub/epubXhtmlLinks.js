var gulp = require('gulp'),
    cheerio = require('gulp-cheerio'),
    debug = require('gulp-debug'),
    paths = require('../paths.js');

// Convert all file names in internal links from .html to .xhtml.
// This is required for epub output to avoid EPUBCheck warnings.
gulp.task('epubXhtmlLinks', function (done) {
    'use strict';

    gulp.src([paths.epub.src, '_site/epub/package.opf', '_site/epub/toc.ncx'], {base: './'})
        .pipe(cheerio({
            run: function ($) {
                var target, newTarget;
                $('[href*=".html"], [src*=".html"]').each(function () {
                    if ($(this).attr('href')) {
                        target = $(this).attr('href');
                    } else if ($(this).attr('src')) {
                        target = $(this).attr('src');
                    } else {
                        return;
                    }

                    if (target.includes('.html') && !target.includes('http')) {
                        newTarget = target.replace('.html', '.xhtml');
                        if ($(this).attr('href')) {
                            $(this).attr('href', newTarget);
                        } else if ($(this).attr('src')) {
                            $(this).attr('src', newTarget);
                        }
                    }
                });
            },
            parserOptions: {
                xmlMode: true
            }
        }))
        .pipe(debug({title: 'Converting internal links to .xhtml in '}))
        .pipe(gulp.dest('./'));
    done();
});
