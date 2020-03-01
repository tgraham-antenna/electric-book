var gulp = require('gulp');

// A function for loading book metadata as an object
function loadMetadata() {
    'use strict';

    var paths = [];
    var filePaths = [];
    var books = [];
    var languages = [];

    if (fileExists.sync('_data/meta.yml')) {

        var metadata = yaml.load(fs.readFileSync('_data/meta.yml', 'utf8'));
        var works = metadata.works;

        var i;
        var j;
        for (i = 0; i < works.length; i += 1) {
            books.push(works[i].directory);
            paths.push('_site/' + works[i].directory + '/text/');
            filePaths.push('_site/' + works[i].directory + '/text/*.html');
            if (works[i].translations) {
                for (j = 0; j < works[i].translations.length; j += 1) {
                    languages.push(works[i].translations[j].directory);
                    paths.push('_site/' + works[i].directory + '/' + works[i].translations[j].directory + '/text/');
                    filePaths.push('_site/' + works[i].directory + '/' + works[i].translations[j].directory + '/text/*.html');
                }
            }
        }
    }

    return {
        books: books,
        languages: languages,
        paths: paths,
        filePaths: filePaths
    };
}

module.exports = loadMetadata;
