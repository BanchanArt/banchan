let Theme = {
    mounted() {
      const current = document.documentElement.getAttribute("data-theme");
      document.querySelector("#theme_toggle").checked = current === "dark";
      this.handleEvent("toggle_theme", () => {
        const current = document.documentElement.getAttribute("data-theme");
        const next = current === "light" ? "dark" : "light";
        document.documentElement.setAttribute("data-theme", next);
        localStorage.setItem("theme", next);
      })
    }
};

export { Theme };
