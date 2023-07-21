import {
  createIcons,
  CheckCircle2,
  ChevronDown,
  LogIn,
  Minus,
  Plus,
  PlusCircle,
  Trash2
} from "lucide";

// Add icons we want to enable here, and to the import above.
const enabledIcons = {
  CheckCircle2,
  ChevronDown,
  LogIn,
  Minus,
  Plus,
  PlusCircle,
  Trash2
};

export const Icon = {
  mounted() {
    // TODO: this will replace _all_ icons on the page, _every time_ this is
    // called. Probably fine for now, but we should probably do something like
    // lucide's internal `replaceElement` does, later.
    replaceIcons();
  }
};

export function replaceIcons() {
  createIcons({ icons: enabledIcons });
}
