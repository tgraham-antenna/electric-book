/* jslint browser */
/*globals window */

function ebFootnotePopups() {
    'use strict';

    // list the features we use
    var featuresSupported = navigator.userAgent.indexOf('Opera Mini') === -1 &&
            document.querySelector !== "undefined" &&
            window.addEventListener !== "undefined" &&
            !!Array.prototype.forEach;

    // get all the .footnote s
    var footnoteLinks = document.querySelectorAll('.footnote');

    // early exit for unsupported or if there are no footnotes
    if (!featuresSupported || footnoteLinks.length === 0) {
        return;
    }

    // loop through footnotes
    footnoteLinks.forEach(function (current) {

        // get the target ID
        var targetHash = current.hash;
        var targetID = current.hash.replace('#', '');

        // escape it with double backslashes, for querySelector
        var sanitisedTargetHash = targetHash.replace(':', '\\:');

        // find the li with the ID from the .footnote's href
        var targetReference = document.querySelector(sanitisedTargetHash);

        // make a div.reference
        var footnoteContainer = document.createElement('div');
        footnoteContainer.classList.add('footnote-detail');
        footnoteContainer.classList.add('visuallyhidden');
        footnoteContainer.id = 'inline-' + targetID;

        // the a, up to the sup
        var theSup = current.parentNode;
        var theContainingElement = current.parentNode.parentNode;

        // add the reference div
        theContainingElement.appendChild(footnoteContainer);

        // move the li contents inside the div.reference
        footnoteContainer.innerHTML = targetReference.innerHTML;

        // show on hover
        theSup.addEventListener('mouseover', function (ev) {
            if (ev.target.classList.contains('footnote')) {
                footnoteContainer.classList.remove('visuallyhidden');
            }
        });

        // add a class to the parent
        theContainingElement.parentNode.classList.add('contains-footnote');

        // if we mouseleave footnoteContainer, hide it
        // (mouseout also fires on mouseout of children, so we use mouseleave)
        footnoteContainer.addEventListener('mouseleave', function (ev) {
            if (ev.target === this) {
                setTimeout(function () {
                    footnoteContainer.classList.add('visuallyhidden');
                }, 1000);
            }
        });

        // Clicking on the reverseFootnote link closes the footnote
        var reverseFootnote = footnoteContainer.querySelector('.reversefootnote');

        // remove the contents since we're using
        // CSS and :before to show a close button marker
        reverseFootnote.innerText = '';

        reverseFootnote.addEventListener('click', function (ev) {
            ev.preventDefault();
            footnoteContainer.classList.add('visuallyhidden');
        });

        // remove the href to avoiding jumping down the page
        current.removeAttribute('href');

    });
}

ebFootnotePopups();
