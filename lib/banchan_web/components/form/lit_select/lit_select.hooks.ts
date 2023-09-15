import { LitElement, adoptStyles, html, css } from "lit";
import { classMap } from "lit/directives/class-map.js";
import { customElement, property, state } from "lit/decorators.js";
// import { Hook, makeHook } from "phoenix_typed_hook";

// class LitSelectHook extends Hook {
//   el: LitSelectElement;

//   mounted() {
//     this.el.hook = this;
//   }

//   destroyed() {
//     this.el.hook = null;
//   }
// }

// export const LitSelect = makeHook(LitSelectHook);

// TODO:
// * Incremental search (String#includes() is probably good enough here)
// * Show pills for current selections in input box, like Tags does.
// * Transitions
// * Make sure mobile doesn't zoom on focus? Maybe? Should probably leave this
//   alone.

@customElement("bc-lit-select")
export class LitSelectElement extends LitElement {
  static styles = css`
    ::slotted(*) {
      display: none;
    }
  `;

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

  connectedCallback() {
    super.connectedCallback();
    // This is so we can use Tailwind styles.
    adoptStyles(this.shadowRoot, [
      LitSelectElement.styles,
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
    this.querySelectorAll("option").forEach((option, index) => {
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
      this.selected = new Set(this.selected);
    } else {
      this.selected = new Set([index]);
    }

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
        e.stopPropagation();
        if (this.highlighted != null) {
          this._select(this.highlighted);
        }
        break;
      case "ArrowDown":
        this._down();
        break;
      case "ArrowUp":
        this._up();
        break;
    }
    e.preventDefault();
  }

  _down() {
    if (this.highlighted == null) {
      this.highlighted = 0;
      return;
    }
    const items = this.querySelectorAll("option");
    const max = items.length - 1;
    this.highlighted = this.highlighted === max ? 0 : this.highlighted + 1;
  }

  _up() {
    const items = this.querySelectorAll("option");
    const max = items.length - 1;
    if (this.highlighted == null) {
      this.highlighted = max;
      return;
    }
    this.highlighted = this.highlighted === 0 ? max : this.highlighted - 1;
  }

  // Render the UI as a function of component state
  render() {
    return html`<div @keydown=${this._handleKeydown}>
      <div class="relative mt-2">
        <input
          id="combobox"
          type="text"
          class="w-full bg-p-0 input input-bordered focus:ring focus:ring-primary"
          ,
          role="combobox"
          aria-controls="options"
          aria-expanded="${this.open}"
          @focus=${() => {
            this.open = true;
          }}
          @click=${() => {
            this.open = true;
          }}
        />
        <button
          type="button"
          class="absolute inset-y-0 right-0 h-full rounded-r-md px-2 focus:outline-none"
          @click=${() => {
            this.open = !this.open;
          }}
        >
          <div class="flex items-center">
            <svg
              class="h-5 w-5 text-base-content"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a.75.75 0 01.55.24l3.25 3.5a.75.75 0 11-1.1 1.02L10 4.852 7.3 7.76a.75.75 0 01-1.1-1.02l3.25-3.5A.75.75 0 0110 3zm-3.76 9.2a.75.75 0 011.06.04l2.7 2.908 2.7-2.908a.75.75 0 111.1 1.02l-3.25 3.5a.75.75 0 01-1.1 0l-3.25-3.5a.75.75 0 01.04-1.06z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
        </button>
        <ul
          class="relative z-40 mt-1 max-h-60 w-full overflow-auto rounded-md bg-base-100 py-1 text-base shadow-lg ring-1 ring-base-300 ring-opacity-5 focus:outline-none sm:text-sm ${classMap(
            { hidden: !this.open }
          )}"
          id="options"
          role="listbox"
        >
          ${Array.from(this.querySelectorAll("option")).map((option, index) => {
            let selected = this.selected?.has(index) ?? false;
            let highlighted = this.highlighted === index;
            return html`
              <li
                class="relative cursor-default select-none py-2 pl-3 pr-9 text-base-content ${classMap(
                  {
                    "text-primary-content": highlighted,
                    "bg-primary": highlighted,
                  }
                )}"
                id="option-${index}"
                role="option"
                tabindex="-1"
                @mouseenter=${() => {
                  this.highlighted = index;
                }}
                @click=${() => this._select(index)}
              >
                <span
                  class="truncate ${classMap({
                    "font-semibold": selected,
                  })}"
                  >${option.innerText}</span
                >
                <span
                  class="absolute inset-y-0 right-0 pr-4 ${classMap({
                    hidden: !selected,
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
      </div>
    </div> `;
  }
}
