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

document.addEventListener("turbolinks:load", function() {
  // Only initialize panel if not yet initialized
  if(!$('#panel .tree ul li').length) {
    $('#links').hide();
    var panel = new Searchdoc.Panel($('#panel'), search_data, tree);
    var s = window.location.search.match(/\?q=([^&]+)/);
    if (s) {
      s = decodeURIComponent(s[1]).replace(/\+/g, ' ');
      if (s.length > 0) {
        $('#search').val(s);
        panel.search(s, true);
      }
    }
    panel.toggle(JSON.parse($('meta[name="data-tree-keys"]').attr("content")));
  }
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
