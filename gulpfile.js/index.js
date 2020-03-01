/*jslint node, for, this */

// This gulpfile processes:
// - images, optimising them for output formats
// - Javascript, optionally, minifying scripts for performance
// - HTML, rendering MathJax as MathML.
// It takes two arguments: --book and --language, e.g.:
// gulp --book samples --language fr

// Get Node modules
var gulp = require('gulp');
var requireDir = require('require-dir');

// Get epub tasks
var epub = requireDir('epub');

// when running `gulp`, do the image tasks
var images = require('./images.js');
gulp.task('default', gulp.series(
    'images:svg',
    'images:printpdf',
    'images:optimise',
    'images:small',
    'images:medium',
    'images:large',
    'images:xlarge',
    'images:max'
));

