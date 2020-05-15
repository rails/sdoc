function toggleSource(id) {
  var src = $('#' + id).toggle();
  var isVisible = src.is(':visible');
  $('#l_' + id).html(isVisible ? 'hide' : 'show');
}

window.highlight = function(url) {
  var hash = url.match(/#([^#]+)$/);
  if (hash) {
    var link = document.querySelector('a[name=' + hash[1] + ']');
    if(link) {
      var parent = link.parentElement;

      parent.classList.add('highlight');

      setTimeout(function() {
        parent.classList.remove('highlight');
      }, 1000);
    }
  }
};

document.addEventListener("turbolinks:load", function() {
  highlight('#' + location.hash);
  $('.description pre').each(function() {
    hljs.highlightBlock(this);
  });
});

// Keep scroll position for panel
(function() {
  var scrollTop = 0;

  addEventListener("turbolinks:before-render", function() {
    scrollTop = $('#panel').first().scrollTop();
  })

  addEventListener("turbolinks:render", function() {
    $('#panel').first().scrollTop(scrollTop);
  })
})()
