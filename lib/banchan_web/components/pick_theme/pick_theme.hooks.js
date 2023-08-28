export const PickTheme = {
  mounted() {
    const current = document.documentElement.getAttribute("data-theme");
    this.pushEventTo(this.el, "theme_changed", { theme: current });
    this.handleEvent("set_theme", ({theme}) => {
      document.documentElement.setAttribute("data-theme", theme);
      localStorage.setItem("theme", theme);
    })
  }
};
