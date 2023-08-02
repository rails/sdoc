window.spotlight = function(url) {
  var hash = url.match(/#([^#]+)$/);
  if (hash) {
    var link = document.querySelector('a[name=' + hash[1] + ']');
    if(link) {
      var parent = link.parentElement;

      parent.classList.add('spotlight');

      setTimeout(function() {
        parent.classList.remove('spotlight');
      }, 1000);
    }
  }
};

document.addEventListener("turbo:load", function() {
  spotlight('#' + location.hash);
});

document.addEventListener("turbo:load", function() {
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

  addEventListener("turbo:before-render", function() {
    scrollTop = document.querySelector(".panel__tree").scrollTop
  })

  addEventListener("turbo:render", function() {
    document.querySelector(".panel__tree").scrollTop = scrollTop
  })
})()

document.addEventListener("turbo:load", function () {
  var backToTop = $("a.back-to-top");

  backToTop.on("click", function (e) {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
  });

  var toggleBackToTop = function () {
    if (window.scrollY > 300) {
      backToTop.addClass("show");
    } else {
      backToTop.removeClass("show");
    }
  }

  $(document).scroll(toggleBackToTop);
})
