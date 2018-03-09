// Store language preference.
// Depends on localstorage.js

var languageSelectors = document.querySelector('[data-lang]');

for (var i = 0; i < languageSelectors.length; i++) {
	var languagePreference = languageSelectors[i].getAttribute('data-lang');
	languageSelectors[i].addEventListener('click', function(){
		localStorage.removeItem('language');
	    localStorage.setItem('language', languagePreference);
	});
};
