let styleText = "";

for (let i = 0; i < document.styleSheets.length; i++) {
  const styleSheet = document.styleSheets[i];
  if (styleSheet.href && new URL(styleSheet.href).hostname !== window.location.hostname) {
    // We can't access cross-origin stylesheets, which are often injected by
    // extensions.
    continue;
  }
  for (let j = 0; j < styleSheet.cssRules.length; j++) {
    const cssRule = styleSheet.cssRules[j];
    styleText += "\n"
    styleText += cssRule.cssText;
  }
}

window.STYLES = new CSSStyleSheet();
window.STYLES.replaceSync(styleText);

