var gulp = require('gulp'),
    yaml = require('js-yaml'),
    loadMetadata = require('./metadata.js');

// Validate yaml files
gulp.task('yaml', function (done) {
    'use strict';

    console.log('Checking YAML files...');

    gulp.src(paths.yaml.src)
        .pipe(tap(function (file) {
            try {
                yaml.safeLoad(fs.readFileSync(file.path, 'utf8'));
                console.log(file.basename + ' ✓');
            } catch (e) {
                console.log(''); // empty line space
                console.log('\x1b[35m%s\x1b[0m', 'YAML error in ' + file.path + ':');
                console.log('\x1b[36m%s\x1b[0m', e.message);
                console.log(''); // empty line space
            }
        }));
    done();
});
