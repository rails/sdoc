import searchIndex from "./search-index.js";

export class Search {
  constructor(inputEl, outputEl, resultRenderer) {
    Object.assign(this, { inputEl, outputEl, resultRenderer });

    this.inputEl.addEventListener("input", event => this.search());
    this.inputEl.addEventListener("focusin", event => this.handleFocusIn(event));
    this.inputEl.addEventListener("focusout", event => this.handleFocusOut(event));
    this.outputEl.addEventListener("focusout", event => this.handleFocusOut(event));
    document.addEventListener("keydown", event => this.handleKey(event));

    // Ensure `tabindex` attribute is set. (When it is not set, the `tabIndex`
    // property returns a default value instead of null / undefined.)
    this.outputEl.tabIndex = this.outputEl.tabIndex;

    this.active = document.activeElement === this.inputEl;
  }

  search() {
    const bitPositions = this.compileQuery(this.query);
    let worst;
    this.clearResults();

    for (const entry of searchIndex.entries) {
      const score = this.computeScore(bitPositions, entry[0], entry[1]);
      worst ??= this.worstResult;

      if (score > worst.score) {
        worst.score = score;
        worst.entry = entry;
        worst = null;
      }
    }

    this.renderResults();
  }

  compileQuery(query) {
    query = ` ${query} `;
    const bitPositions = [];

    for (let i = 0, upto = query.length - 2; i < upto; i += 1) {
      const ngram = query.substring(i, i + 3);
      const position = searchIndex.ngrams[ngram];

      if (position) {
        bitPositions.push(position);
      }
    }
    return bitPositions;
  }

  computeScore(bitPositions, bytes, tiebreakerBonus) {
    let score = 0;

    for (let i = 0, len = bitPositions.length; i < len; i += 1) {
      const position = bitPositions[i] | 0;
      const byte = bytes[position / 8 | 0] | 0;
      const mask = 1 << (position % 8) | 0;

      if (byte & mask) {
        score += searchIndex.weights[position] + tiebreakerBonus;
      }
    }

    return score;
  }

  static maxResults = 20;
  results = Array(Search.maxResults).fill().map(() => ({}));

  clearResults() {
    for (const result of this.results) {
      result.score = 0;
      result.entry = null;
    }
  }

  get worstResult() {
    return this.results.reduce((worst, result) => result.score < worst.score ? result : worst);
  }

  renderResults() {
    this.results.sort((a, b) => b.score - a.score);

    let html = "";

    for (const { score, entry } of this.results) {
      if (score > 0) {
        html += this.resultRenderer(entry[2], entry[3], entry[4], entry[5]);
      }
    }

    this.outputEl.innerHTML = html;
    this.cursorEl = this.outputEl.firstElementChild;
  }

  feelingLucky(query) {
    this.query = query;
    this.clickCursor();
  }

  focus() {
    this.inputEl.focus();
  }

  blur() {
    this.inputEl.blur();
  }

  get active() {
    return this.inputEl.classList.contains("active");
  }

  set active(value) {
    this.inputEl.classList.toggle("active", value);
    this.outputEl.classList.toggle("active", value);
  }

  get query() {
    return this.inputEl.value;
  }

  set query(value) {
    this.inputEl.value = value;
    this.search();
  }

  get cursorEl() {
    return this._cursorEl;
  }

  set cursorEl(el) {
    this._cursorEl?.classList?.remove("cursor");
    el?.classList?.add("cursor");
    el?.scrollIntoView({ block: "nearest" });
    this._cursorEl = el;
  }

  incrementCursor() {
    if (this.cursorEl?.nextElementSibling) {
      this.cursorEl = this.cursorEl.nextElementSibling;
    }
  }

  decrementCursor() {
    if (this.cursorEl?.previousElementSibling) {
      this.cursorEl = this.cursorEl.previousElementSibling;
    }
  }

  clickCursor() {
    this.cursorEl?.querySelector("a[href]")?.click();
    setTimeout(() => this.blur(), 0);
  }

  handleFocusIn() {
    this.active = true;
  }

  handleFocusOut({ relatedTarget }) {
    this.active = this.inputEl === relatedTarget || this.outputEl.contains(relatedTarget);
  }

  static activeKeyMap = {
    "ArrowDown": "incrementCursor",
    "ArrowUp": "decrementCursor",
    "Enter": "clickCursor",
    "Escape": "blur"
  };

  static idleKeyMap = {
    "/": "focus"
  };

  handleKey(event) {
    const handler = (this.active ? Search.activeKeyMap : Search.idleKeyMap)[event.key];
    if (handler) {
      this[handler]();
      event.preventDefault();
    }
  }
}
