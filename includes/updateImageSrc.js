// Author: Mickaël Canouil
// Version: <1.0.0>
// Description: Change image src depending on body class (quarto-light or quarto-dark)
// License: MIT
function updateImageSrc() {
  var bodyClass = window.document.body.classList;
  var images = window.document.getElementsByTagName('img');
  for (var i = 0; i < images.length; i++) {
    var image = images[i];
    var src = image.src;
    var newSrc = src;
    if (bodyClass.contains('quarto-light') && src.includes('.dark')) {
      newSrc = src.replace('.dark', '.light');
    } else if (bodyClass.contains('quarto-dark') && src.includes('.light')) {
      newSrc = src.replace('.light', '.dark');
    }
    if (newSrc !== src) {
      image.src = newSrc;
    }
  }
}

var observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
    if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
      updateImageSrc();
    }
  });
});

observer.observe(window.document.body, {
  attributes: true
});

updateImageSrc();
