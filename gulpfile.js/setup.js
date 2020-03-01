var gulp = require('gulp'),
    fs = require('fs'),
    yaml = require('js-yaml'),
    args = require('yargs').argv;

// Load image settings if they exist
var imageSettings = [];
if (fs.existsSync('_data/images.yml')) {
    imageSettings = yaml.load(fs.readFileSync('_data/images.yml', 'utf8'));
}

// Get the book we're processing
var book = 'book';
if (args.book && args.book.trim !== '') {
    book = args.book;
}

// let '--folder' be an alias for '--book',
// to make sense for gulping 'assets' and '_items'
if (args.folder && args.folder.trim !== '') {
    book = args.folder;
}

// Reminder on usage
if (book === 'book') {
    console.log('If processing images for a book that\'s not in the /book directory, use the --book argument, e.g. gulp --book potatoes');
    console.log('To process images in _items, use gulp --book _items');
}

// Get the language we're processing
var language = '';
if (args.language && args.language.trim !== '') {
    language = '/' + args.language;
}

// Reminder on usage
if (language === '') {
    console.log('If processing a translation\'s images, use the --language argument, e.g. gulp --language fr');
}

module.exports = {
    imageSettings: imageSettings,
    book: book,
    language: language
}
