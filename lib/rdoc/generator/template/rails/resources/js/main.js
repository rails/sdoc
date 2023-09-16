import { Search } from "./search.js";

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

document.addEventListener("turbo:load", () => {
  const searchInput = document.getElementById("search");
  const searchOutput = document.getElementById("results");
  const search = new Search(searchInput, searchOutput, (url, module, method, summary) =>
    `<div class="results__result">
      <a class="result__link" href="${url}">
        <code class="result__module">${module.replaceAll("::", "::<wbr>")}</code>
        <code class="result__method">${method || ""}</code>
      </a>
      <p class="result__summary description">${summary || ""}</p>
    </div>`
  );

  // Handle query button clicks.
  document.addEventListener("click", ({ target }) => {
    const query = target.closest(".query-button")?.dataset?.query;
    if (query) {
      search.query = query;
      search.focus();
    }
  });

  const query = new URL(document.location).searchParams.get("q");
  if (query) {
    search.feelingLucky(query);
  }
}, { once: true });

document.addEventListener("turbo:load", function() {
  $('#links').hide();
});


// Hide menu on mobile when navigating to a named anchor on the current page.
// For example, when clicking on a method in the method list.
window.addEventListener("hashchange", () => {
  document.getElementById("panel__state").checked = false;
});


// Because search results are in a `data-turbo-permanent` element, manually blur
// to hide them when navigating.
document.addEventListener("turbo:click", ({ target }) => {
  if (document.getElementById("results").contains(target)) {
    target.blur();
  }
});


// Keep scroll position for search results across Turbo page loads.
(function() {
  var scrollTop = 0;

  addEventListener("turbo:before-render", function() {
    scrollTop = document.getElementById("results").scrollTop
  })

  addEventListener("turbo:render", function() {
    document.getElementById("results").scrollTop = scrollTop
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
