import { LitElement, adoptStyles, html, css } from "lit";
import { classMap } from "lit/directives/class-map.js";
import { customElement, property, state } from "lit/decorators.js";

// TODO:
// * highlight multiple things, incl. Shift+arrow management
// * Allow combo vs dropdown modes.
// * slot-based custom styling for option bodies.
// * Transitions

@customElement("bc-combo-box")
export class ComboBoxElement extends LitElement {
  static styles = css``;

  // @property()
  // hook?: LitSelectHook;

  @property()
  open?: boolean = false;

  @property({ type: Boolean })
  multi: boolean = false;

  @state()
  selected: Set<number> = new Set();

  @state()
  highlighted?: number;

  @state()
  filter?: string;

  connectedCallback() {
    super.connectedCallback();
    // This is so we can use Tailwind styles.
    adoptStyles(this.shadowRoot, [
      ComboBoxElement.styles,
      (window as any).STYLES,
    ]);
    document.addEventListener("keydown", this._handleDocKeydown);
    window.addEventListener("click", this._handleDocClick);
    this._updateSelected();
  }

  disconnectedCallback(): void {
    document.removeEventListener("keydown", this._handleDocKeydown);
    window.removeEventListener("click", this._handleDocClick);
    super.disconnectedCallback();
  }

  _getOptions(all = false) {
    return Array.from(this.querySelectorAll("option"))
      .map((option, index) => ({ option, index }))
      .filter(({ option }) => {
        if (all) {
          return true;
        } else if (this.filter) {
          return option.innerText
            .toUpperCase()
            .includes(this.filter.toUpperCase());
        } else {
          return true;
        }
      });
  }

  _handleDocKeydown = (event: KeyboardEvent) => {
    if (event.key === "Escape") {
      this.open = false;
    }
  };

  _handleDocClick = (event: MouseEvent) => {
    if (!this.contains(event.target as HTMLElement)) {
      this.open = false;
    }
  };

  _updateSelected() {
    this._getOptions().forEach(({ option, index }) => {
      if (option.hasAttribute("selected")) {
        this.selected.add(index);
      }
    });
    this.selected = new Set(this.selected);
  }

  _select(index: number) {
    const wasSelected = this.selected.has(index);
    // Trigger a render.
    if (this.multi) {
      if (wasSelected) {
        this.selected.delete(index);
      } else {
        this.selected.add(index);
      }
    } else {
      this.selected.clear();
      this.selected.add(index);
    }

    this.requestUpdate();

    const option = this.querySelectorAll("option")[index];
    if (option) {
      if (this.multi && wasSelected) {
        option.removeAttribute("selected");
      } else {
        option.setAttribute("selected", "selected");
      }
    }

    // Tell LiveView about the change.
    this.querySelector("select")?.dispatchEvent(
      new Event("change", {
        bubbles: true,
        cancelable: true,
      })
    );
  }

  _handleKeydown(e: KeyboardEvent) {
    switch (e.key) {
      case "Enter":
        if (e.ctrlKey) {
          e.stopPropagation();
          e.preventDefault();
          this.querySelector("select")?.form?.dispatchEvent(
            new Event("submit", { bubbles: true, cancelable: true })
          );
        } else {
          if (this.highlighted != null) {
            this._select(this.highlighted);
          }
        }
        break;
      case "ArrowDown":
        this._down();
        e.preventDefault();
        break;
      case "ArrowUp":
        this._up();
        e.preventDefault();
        break;
    }
  }

  _down() {
    if (this.highlighted == null) {
      this.highlighted = 0;
      return;
    }
    const items = this._getOptions();
    const max = items[items.length - 1]?.index;
    if (max == null) {
      this.highlighted = null;
      return;
    }
    this.highlighted =
      this.highlighted === max
        ? items[0]?.index
        : items.find(({ index }) => index > this.highlighted)?.index ?? 0;
  }

  _up() {
    const items = this._getOptions();
    const max = items[items.length - 1]?.index;
    if (max == null) {
      this.highlighted = null;
      return;
    }
    if (this.highlighted == null) {
      this.highlighted = max;
      return;
    }
    this.highlighted =
      this.highlighted === items[0]?.index
        ? max
        : items.findLast(({ index }) => index < this.highlighted)?.index ?? 0;
  }

  render() {
    return html`<div
      class="w-full bg-p-0"
      @focusout=${(e: FocusEvent) => {
        this.open = (e.currentTarget as HTMLElement).contains(
          e.relatedTarget as HTMLElement
        );
      }}
    >
      <ul
        class="flex flex-row items-center flex-wrap p-2 gap-2 border focus-within:ring ring-primary border-base-content border-opacity-20 bg-base-100 rounded-btn cursor-text"
        role="combobox"
        aria-controls="options"
        aria-expanded="${this.open}"
        @focus=${() => {
          this.open = true;
        }}
        @click=${() => {
          this.open = true;
          this.shadowRoot?.querySelector("input")?.focus();
        }}
      >
        ${this.multi
          ? this._getOptions(true)
              .filter(({ index }) => this.selected.has(index))
              .map(({ option, index }) => {
                return html`
                  <li
                    class="flex flex-row items-center max-w-full gap-1 px-2 py-1 text-xs font-semibold text-opacity-75 no-underline uppercase rounded-full cursor-default bg-opacity-10 h-full w-fit hover:bg-opacity-20 active:bg-opacity-20 border-base-content border-opacity-10 hover:text-opacity-100 active:text-opacity-100 bg-base-content"
                  >
                    <span class="tracking-wide truncate"
                      >${option.innerText}</span
                    >
                    <button
                      type="button"
                      class="text-xs opacity-50 cursor-pointer hover:opacity-100 active:opacity-100"
                      aria-controls="options"
                      aria-label="Remove ${option.innerText}"
                      @focusout=${(e) => e.stopPropagation()}
                      @click=${(e) => {
                        e.stopPropagation();
                        this._select(index);
                      }}
                      @focus=${(e) => e.stopPropagation()}
                    >
                      ✕
                    </button>
                  </li>
                `;
              })
          : html`<li>
              ${this._getOptions(true).find((o) => this.selected.has(o.index))
                ?.option.innerText ?? ""}
            </li>`}
        <li>
          <input
            type="text"
            class="w-full h-full px-0 overflow-hidden border-transparent border-none shadow-none input-field bg-base-100 input-sm focus:outline-none focus:border-none focus:border-transparent focus:ring-0 focus:ring-transparent"
            @input=${(e) => {
              this.filter = (e.target as HTMLInputElement).value;
            }}
            @keydown=${this._handleKeydown}
          />
        </li>
      </ul>
      <ul
        class="flex flex-col z-40 mt-1 max-h-60 overflow-auto rounded-md bg-base-100 py-1 text-base shadow-lg ring-1 ring-base-300 ring-opacity-5 focus:outline-none sm:text-sm ${classMap(
          { hidden: !this.open }
        )}"
        id="options"
        role="listbox"
      >
        ${this._getOptions().map(({ option, index }) => {
          let selected = this.selected?.has(index) ?? false;
          let highlighted = this.highlighted === index;
          return html`
            <li
              class="flex flex-row items-center cursor-default select-none py-2 px-3 text-base-content ${classMap(
                {
                  "text-primary-content": highlighted,
                  "bg-primary": highlighted,
                }
              )}"
              id="option-${index}"
              role="option"
              tabindex="-1"
              aria-selected="${highlighted}"
              aria-checked="${selected}"
              aria-label=${option.innerText}
              @mouseenter=${() => {
                this.highlighted = index;
              }}
              @click=${() => this._select(index)}
            >
              <span
                class="flex-1 ${classMap({
                  "font-semibold": selected,
                })}"
                >${option.innerText}</span
              >
              <span
                class="whitespace-nowrap pl-2 ${classMap({
                  invisible: !selected,
                  "text-primary": !highlighted,
                  "text-primary-content": highlighted,
                })}"
                aria-hidden="${!selected}"
              >
                <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                    clip-rule="evenodd"
                  />
                </svg>
              </span>
            </li>
          `;
        })}
      </ul>
    </div> `;
  }
}
