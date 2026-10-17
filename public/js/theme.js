// Dark / light theme. Loaded in <head> (before the page paints) so a saved
// choice never flashes the wrong colours. With no saved choice, the visitor's
// system setting decides, via the stylesheet alone; this file only adds the
// toggle button and remembers the choice. Without JavaScript the site still
// works, it just has no toggle.
(function () {
  var KEY = "site-theme";
  var root = document.documentElement;

  function read() {
    try {
      var value = window.localStorage.getItem(KEY);
      return value === "dark" || value === "light" ? value : null;
    } catch (e) {
      return null;
    }
  }

  function write(value) {
    try {
      window.localStorage.setItem(KEY, value);
    } catch (e) {
      /* storage blocked: the choice lasts for this page only */
    }
  }

  function current() {
    var saved = root.getAttribute("data-theme");
    if (saved) return saved;
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
  }

  var saved = read();
  if (saved) root.setAttribute("data-theme", saved);

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.querySelector("[data-theme-toggle]");
    if (!button) return;
    button.hidden = false;
    button.addEventListener("click", function () {
      var next = current() === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      write(next);
    });
  });
})();
