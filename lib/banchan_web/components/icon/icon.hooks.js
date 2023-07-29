import {
  createIcons,
  Check,
  CheckCircle2,
  ChevronDown,
  LogIn,
  Minus,
  Pencil,
  Plus,
  PlusCircle,
  Replace,
  Trash2,
  X
} from "lucide";

// Add icons we want to enable here, and to the import above.
const enabledIcons = {
  Check,
  CheckCircle2,
  ChevronDown,
  LogIn,
  Minus,
  Pencil,
  Plus,
  PlusCircle,
  Replace,
  Trash2,
  X
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
