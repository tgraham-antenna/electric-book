var gulp = require('gulp'),
    newer = require('gulp-newer'),
    responsive = require('gulp-responsive-images'),
    gm = require('gulp-gm'),
    svgmin = require('gulp-svgmin'),
    fileExists = require('file-exists'),
    tap = require('gulp-tap'),
    debug = require('gulp-debug'),
    rename = require('gulp-rename'),
    paths = require('./paths.js'),
    imageSettings = require('./setup.js').imageSettings;

// Set filetypes to convert, comma separated, no spaces
var filetypes = 'jpg,jpeg,gif,png';

// Minify and clean SVGs and copy to destinations.
// For EpubCheck-safe SVGs, we remove data- attributes
// and don't strip defaults like <style "type=text/css">
gulp.task('images:svg', function (done) {
    'use strict';
    console.log('Processing SVG images from ' + paths.img.source);
    var prefix = '';
    gulp.src(paths.img.source + '*.svg')
        .pipe(debug({title: 'Processing SVG '}))
        .pipe(tap(function (file) {
            prefix = file.basename.replace('.', '').replace(' ', '');
        }))
        .pipe(svgmin(function getOptions() {
            return {
                plugins: [
                    {
                        // We definitely want a viewBox
                        removeViewBox: false
                    },
                    {
                        // With a viewBox, we can remove these
                        removeDimensions: true
                    },
                    {
                        // We can remove data- attributes
                        removeAttrs: {
                            attrs: 'data.*'
                        }
                    },
                    {
                        // Remove unknown elements, but not default values
                        removeUnknownsAndDefaults: {
                            defaultAttrs: false
                        }
                    },
                    {
                        // We want titles for accessibility
                        removeTitle: false
                    },
                    {
                        // We want descriptions for accessibility
                        removeDesc: false
                    },
                    {
                        // Default
                        convertStyleToAttrs: true
                    },
                    {
                        // Default
                        removeUselessStrokeAndFill: true
                    },
                    {
                        // Default
                        inlineStyles: true
                    },
                    {
                        // Default
                        cleanupAttrs: true
                    },
                    {
                        // Default
                        removeDoctype: true
                    },
                    {
                        // Default
                        removeXMLProcInst: true
                    },
                    {
                        // Default
                        removeComments: true
                    },
                    {
                        // Default
                        removeMetadata: true
                    },
                    {
                        // Default
                        removeUselessDefs: true
                    },
                    {
                        // Default
                        removeXMLNS: false
                    },
                    {
                        // Default
                        removeEditorsNSData: true
                    },
                    {
                        // Default
                        removeEmptyAttrs: true
                    },
                    {
                        // Default
                        removeHiddenElems: true
                    },
                    {
                        // Default
                        removeEmptyText: true
                    },
                    {
                        // Default
                        removeEmptyContainers: true
                    },
                    {
                        // Default
                        cleanupEnableBackground: true
                    },
                    {
                        // Default
                        minifyStyles: true
                    },
                    {
                        // Default
                        convertColors: true
                    },
                    {
                        // Default
                        convertPathData: true
                    },
                    {
                        // Default
                        convertTransform: true
                    },
                    {
                        // Default
                        removeNonInheritableGroupAttrs: true
                    },
                    {
                        // Default
                        removeUselessStrokeAndFill: true
                    },
                    {
                        // Default
                        removeUnusedNS: true
                    },
                    {
                        // Default
                        prefixIds: false
                    },
                    {
                        // Prefix and minify IDs
                        cleanupIDs: {
                            prefix: prefix + '-',
                            minify: true
                        }
                    },
                    {
                        // Default
                        cleanupNumericValues: true
                    },
                    {
                        // Default
                        cleanupListOfValues: true
                    },
                    {
                        // Default
                        moveElemsAttrsToGroup: true
                    },
                    {
                        // Default
                        collapseGroups: true
                    },
                    {
                        // Default
                        removeRasterImages: false
                    },
                    {
                        // Default
                        mergePaths: true
                    },
                    {
                        // Default
                        convertShapeToPath: false
                    },
                    {
                        // Default
                        convertEllipseToCircle: true
                    },
                    {
                        // Default
                        sortAttrs: false
                    },
                    {
                        // Default
                        sortDefsChildren: true
                    },
                    {
                        // Default
                        removeAttributesBySelector: false
                    },
                    {
                        // Default
                        removeElementsByAttr: false
                    },
                    {
                        // Default
                        addClassesToSVGElement: false
                    },
                    {
                        // Default
                        addAttributesToSVGElement: false
                    },
                    {
                        // Default
                        removeOffCanvasPaths: false
                    },
                    {
                        // Default
                        removeStyleElement: false
                    },
                    {
                        // Default
                        removeScriptElement: false
                    },
                    {
                        // Default
                        reusePaths: false
                    }
                ]
            };
        }).on('error', function (e) {
            console.log(e);
        }))
        .pipe(gulp.dest(paths.img.printpdf))
        .pipe(gulp.dest(paths.img.screenpdf))
        .pipe(gulp.dest(paths.img.web))
        .pipe(gulp.dest(paths.img.epub))
        .pipe(gulp.dest(paths.img.app));
    done();
});

// Convert source images for print-pdf
gulp.task('images:printpdf', function (done) {
    'use strict';

    // Options
    var printPDFColorProfile = 'PSOcoated_v3.icc';
    var printPDFColorSpace = 'cmyk';
    var printPDFColorProfileGrayscale = 'Grey_Fogra39L.icc';
    var printPDFColorSpaceGrayscale = 'gray';

    console.log('Processing print-PDF images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + printPDFColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.printpdf))
            .pipe(debug({title: 'Creating print-PDF version of '}))
            .pipe(gm(function (gmfile) {

                // Check for grayscale
                var thisColorProfile = printPDFColorProfile; // set default/fallback
                var thisColorSpace = printPDFColorSpace; // set default/fallback
                var thisFilename = gmfile.source.split('\/').pop(); // for unix slashes
                thisFilename = thisFilename.split('\\').pop(); // for windows backslashes

                // Look up image colour settings
                imageSettings.forEach(function (image) {
                    if (image.file === thisFilename) {
                        if (image['print-pdf'].colorspace === 'gray') {
                            thisColorProfile = printPDFColorProfileGrayscale;
                            thisColorSpace = printPDFColorSpaceGrayscale;
                        }
                    }
                });

                return gmfile.profile('_tools/profiles/' + thisColorProfile).colorspace(thisColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gulp.dest(paths.img.printpdf));
    } else {
        console.log('Colour profile _tools/profiles/' + printPDFColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});

// Convert and optimise source images
// for screen-pdf, web, epub, and app
gulp.task('images:optimise', function (done) {
    'use strict';

    // Options
    var imagesOptimiseColorProfile = 'sRGB_v4_ICC_preference_displayclass.icc';
    var imagesOptimiseColorSpace = 'rgb';

    console.log('Processing screen-PDF, web, epub and app images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + imagesOptimiseColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.web))
            .pipe(debug({title: 'Optimising '}))
            .pipe(responsive({
                '*': [{
                    width: 810,
                    quality: 90,
                    upscale: false
                }]
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gm(function (gmfile) {
                return gmfile.profile('_tools/profiles/' + imagesOptimiseColorProfile).colorspace(imagesOptimiseColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gulp.dest(paths.img.screenpdf))
            .pipe(gulp.dest(paths.img.web))
            .pipe(gulp.dest(paths.img.epub))
            .pipe(gulp.dest(paths.img.app));
    } else {
        console.log('Colour profile _tools/profiles/' + imagesOptimiseColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});

// Make small images for web use in srcset
gulp.task('images:small', function (done) {
    'use strict';

    // Options
    var imagesSmallColorProfile = 'sRGB_v4_ICC_preference_displayclass.icc';
    var imagesSmallColorSpace = 'rgb';

    console.log('Creating small web images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + imagesSmallColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.web))
            .pipe(debug({title: 'Creating small '}))
            .pipe(responsive({
                '*': [{
                    width: 320,
                    quality: 90,
                    upscale: false,
                    suffix: '-320'
                }]
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gm(function (gmfile) {
                return gmfile.profile('_tools/profiles/' + imagesSmallColorProfile).colorspace(imagesSmallColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gulp.dest(paths.img.web));
    } else {
        console.log('Colour profile _tools/profiles/' + imagesSmallColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});

// Make medium images for web use in srcset
gulp.task('images:medium', function (done) {
    'use strict';

    // Options
    var imagesMediumColorProfile = 'sRGB_v4_ICC_preference_displayclass.icc';
    var imagesMediumColorSpace = 'rgb';

    console.log('Creating medium web images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + imagesMediumColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.web))
            .pipe(debug({title: 'Creating medium '}))
            .pipe(responsive({
                '*': [{
                    width: 640,
                    quality: 90,
                    upscale: false,
                    suffix: '-640'
                }]
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gm(function (gmfile) {
                return gmfile.profile('_tools/profiles/' + imagesMediumColorProfile).colorspace(imagesMediumColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gulp.dest(paths.img.web));
    } else {
        console.log('Colour profile _tools/profiles/' + imagesMediumColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});

// Make large images for web use in srcset
gulp.task('images:large', function (done) {
    'use strict';

    // Options
    var imagesLargeColorProfile = 'sRGB_v4_ICC_preference_displayclass.icc';
    var imagesLargeColorSpace = 'rgb';

    console.log('Creating large web images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + imagesLargeColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.web))
            .pipe(debug({title: 'Creating large '}))
            .pipe(responsive({
                '*': [{
                    width: 1024,
                    quality: 90,
                    upscale: false,
                    suffix: '-1024'
                }]
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gm(function (gmfile) {
                return gmfile.profile('_tools/profiles/' + imagesLargeColorProfile).colorspace(imagesLargeColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gulp.dest(paths.img.web));
    } else {
        console.log('Colour profile _tools/profiles/' + imagesLargeColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});

// Make extra-large images for web use in srcset
gulp.task('images:xlarge', function (done) {
    'use strict';

    // Options
    var imagesXLargeColorProfile = 'sRGB_v4_ICC_preference_displayclass.icc';
    var imagesXLargeColorSpace = 'rgb';

    console.log('Creating extra-large web images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + imagesXLargeColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.web))
            .pipe(debug({title: 'Creating extra-large '}))
            .pipe(responsive({
                '*': [{
                    width: 2048,
                    quality: 90,
                    upscale: false,
                    suffix: '-2048'
                }]
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gm(function (gmfile) {
                return gmfile.profile('_tools/profiles/' + imagesXLargeColorProfile).colorspace(imagesXLargeColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(gulp.dest(paths.img.web));
    } else {
        console.log('Colour profile _tools/profiles/' + imagesXLargeColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});

// Make full-quality images in RGB
gulp.task('images:max', function (done) {
    'use strict';

    // Options
    var imagesMaxColorProfile = 'sRGB_v4_ICC_preference_displayclass.icc';
    var imagesMaxColorSpace = 'rgb';

    console.log('Creating max-quality web images from ' + paths.img.source);
    if (fileExists.sync('_tools/profiles/' + imagesMaxColorProfile)) {
        gulp.src(paths.img.source + '*.{' + filetypes + '}')
            .pipe(newer(paths.img.web))
            .pipe(debug({title: 'Creating max-quality '}))
            .pipe(gm(function (gmfile) {
                return gmfile.quality(100).profile('_tools/profiles/' + imagesMaxColorProfile).colorspace(imagesMaxColorSpace);
            }).on('error', function (e) {
                console.log(e);
            }))
            .pipe(rename({suffix: "-max"}))
            .pipe(gulp.dest(paths.img.web));
    } else {
        console.log('Colour profile _tools/profiles/' + imagesMaxColorProfile + ' not found. Exiting.');
        return;
    }
    done();
});
