import { Search } from "./search.js";

document.addEventListener("turbo:load", () => {
  const searchInput = document.getElementById("search");
  const searchOutput = document.getElementById("results");
  const search = new Search(searchInput, searchOutput, (url, module, member, summary) =>
    `<div class="results__result">
      <a class="ref-link result__link" href="${url}">
        <code class="result__module">${module.replaceAll("::", "::<wbr>")}</code>
        <code class="result__member">${member || ""}</code>
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
})();


// Turbo Drive interferes with the browser designating the `:target` element for
// CSS (see https://github.com/hotwired/turbo/issues/592), so add an explicit
// class instead.
(function() {
  const retarget = (url) => {
    document.querySelector(".target")?.classList?.remove("target");
    if (url.hash) {
      document.getElementById(url.hash.substring(1))?.classList?.add("target");
    }
  };

  // Unlike normal navigation, Turbo Drive fires the `hashchange` _before_
  // `location` is changed, so we must use the `newURL` property.
  window.addEventListener("hashchange", ({ newURL }) => retarget(new URL(newURL)));
  document.addEventListener("turbo:load", event => retarget(location));
})();
