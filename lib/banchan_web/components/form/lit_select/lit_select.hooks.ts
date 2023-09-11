import { LitElement, css, html } from "lit";
import {
  customElement,
  property,
  state,
  queryAssignedElements,
} from "lit/decorators.js";
import { Hook, makeHook } from "phoenix_typed_hook";

class LitSelectHook extends Hook {
  el: LitSelectElement;

  mounted() {
    this.el.hook = this;
  }

  destroyed() {
    this.el.hook = null;
  }
}

export const LitSelect = makeHook(LitSelectHook);

@customElement("bc-lit-select")
export class LitSelectElement extends LitElement {
  @property()
  hook?: LitSelectHook;

  @property()
  selected?: string[] | string;

  @state()
  highlighted?: number;

  @queryAssignedElements({ selector: "option" })
  options!: HTMLElement[];

  protected createRenderRoot(): Element | ShadowRoot {
    // Disable shadow DOM so we use global Tailwind styles
    return this;
  }

  // Render the UI as a function of component state
  render() {
    return html`<div>
      <label
        for="combobox"
        class="block text-sm font-medium leading-6 text-base-content"
      >
        Assigned to
      </label>
      <div class="relative mt-2">
        <input
          id="combobox"
          type="text"
          class="w-full bg-p-0 select select-bordered focus:ring focus:ring-primary"
          ,
          role="combobox"
          aria-controls="options"
          aria-expanded="false"
        />
        <button
          type="button"
          class="absolute inset-y-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none"
        >
          <svg
            class="h-5 w-5 text-gray-400"
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
        </button>

        <ul
          class="absolute z-40 mt-1 max-h-60 w-full overflow-auto rounded-md bg-base-100 py-1 text-base shadow-lg ring-1 ring-base-300 ring-opacity-5 focus:outline-none sm:text-sm"
          id="options"
          role="listbox"
        >
          <slot></slot>
          ${this.options.map((option, index) => {
            return html`
              <!--
        Combobox option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

        Active: "text-white bg-indigo-600", Not Active: "text-gray-900"
      -->
              <li
                class="relative cursor-default select-none py-2 pl-3 pr-9 text-base-content"
                id="option-0"
                role="option"
                tabindex="-1"
              >
                <!-- Selected: "font-semibold" -->
                <span class="block truncate">Leslie Alexander</span>

                <!--
          Checkmark, only display for selected option.

          Active: "text-white", Not Active: "text-indigo-600"
        -->
                
                <span
                  class="absolute inset-y-0 right-0 flex items-center pr-4 text-primary"
                >
                  <svg
                    class="h-5 w-5"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
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
