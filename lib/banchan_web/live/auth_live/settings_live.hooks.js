let Theme = {
  mounted() {
    const current = document.documentElement.getAttribute("data-theme");
    this.pushEvent("theme_changed", { theme: current });
    this.handleEvent("set_theme", ({theme}) => {
      document.documentElement.setAttribute("data-theme", theme);
      localStorage.setItem("theme", theme);
      this.pushEvent("theme_changed", { theme: theme });
    })
  }
};

export { Theme };
