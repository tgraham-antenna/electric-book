var gulp = require('gulp'),
    del = require('del'),
    cheerio = require('gulp-cheerio'),
    debug = require('gulp-debug'),
    rename = require('gulp-rename'),
    paths = require('./paths.js');

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

// Clean out renamed .html files
gulp.task('epubCleanHtmlFiles', function () {
    'use strict';
    console.log('Removing old *.html files in ' + paths.epub.src);
    return del(paths.epub.src);
});

module.exports = {
    epubXhtmlLinks: epubXhtmlLinks,
    epubXhtmlFiles: epubXhtmlFiles,
    epubCleanHtmlFiles: epubCleanHtmlFiles
};
