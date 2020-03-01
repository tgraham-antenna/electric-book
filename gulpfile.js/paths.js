var gulp = require('gulp'),
    book = require('./setup.js').book;
    language = require('./setup.js').language;

// Set up paths.
// Paths to text src must include the *.html extension.
// Add paths to any JS files to minify to the src array, e.g.
// src: ['assets/js/foo.js,assets/js/bar.js'],
var paths = {
    img: {
        source: book + language + '/images/_source/',
        printpdf: book + language + '/images/print-pdf/',
        web: book + language + '/images/web/',
        screenpdf: book + language + '/images/screen-pdf/',
        epub: book + language + '/images/epub/',
        app: book + language + '/images/app/'
    },
    text: {
        src: '_site/' + book + language + '/text/*.html',
        dest: '_site/' + book + language + '/text/'
    },
    epub: {
        src: '_site/epub' + language + '/text/*.html',
        dest: '_site/epub' + language + '/text/'
    },
    js: {
        src: [],
        dest: 'assets/js/'
    },
    yaml: {
        src: ['*.yml', '_configs/*.yml', '_data/*.yml']
    }
};

module.exports = paths;
