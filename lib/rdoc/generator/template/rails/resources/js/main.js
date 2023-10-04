import { Search } from "./search.js";

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


// Turbo Drive interferes with the browser designating the `:target` element for
// CSS. See https://github.com/hotwired/turbo/issues/592.
//
// Therefore, disable Turbo Drive for intra-page link clicks...
document.addEventListener("turbo:click", event => {
  const targetUrl = new URL(event.detail.url);
  if (targetUrl.hash && targetUrl.href === new URL(targetUrl.hash, location).href) {
    event.preventDefault();
  }
});
// ...and, if appropriate, trigger an intra-page navigation after `turbo:load`.
document.addEventListener("turbo:load", event => {
  if (location.hash) {
    const a = document.createElement("a");
    a.href = location;
    a.click();
  }
});


document.addEventListener("turbo:load", function () {
  const backToTop = document.querySelector("a.back-to-top");

  backToTop.addEventListener("click", event => {
    event.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
  });

  document.addEventListener("scroll", event => {
    backToTop.classList.toggle("show", window.scrollY > 300)
  }, { passive: true });
})
