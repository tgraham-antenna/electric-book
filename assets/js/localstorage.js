// Store, retrieve and remove data in localStorage

function getItem(itemName) {
    return localStorage.getItem(itemName);
}

function setItem(itemName, value, expiredays) {
    return localStorage.setItem(itemName, value);
}

function removeItem(itemName) {
    return localStorage.removeItem(itemName);
}
