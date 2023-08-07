import {
  createIcons,
  Bell,
  Bot,
  Bug,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  CircleSlash,
  ClipboardSignature,
  Coins,
  Component,
  Flag,
  Gavel,
  Home,
  Inbox,
  LayoutDashboard,
  LayoutList,
  LayoutPanelTop,
  LogIn,
  LogOut,
  MailOpen,
  Minus,
  Palette,
  Pencil,
  Plus,
  PlusCircle,
  Replace,
  ScrollText,
  Search,
  Settings,
  ShieldCheck,
  ShoppingBag,
  Store,
  Terminal,
  Trash2,
  User,
  Users,
  UserPlus,
  X
} from "lucide";

// Add icons we want to enable here, and to the import above.
const enabledIcons = {
  Bell,
  Bot,
  Bug,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronRight,
  CircleSlash,
  ClipboardSignature,
  Coins,
  Component,
  Flag,
  Gavel,
  Home,
  Inbox,
  LayoutDashboard,
  LayoutList,
  LayoutPanelTop,
  LogIn,
  LogOut,
  MailOpen,
  Minus,
  Palette,
  Pencil,
  Plus,
  PlusCircle,
  Replace,
  ScrollText,
  Search,
  Settings,
  ShieldCheck,
  ShoppingBag,
  Store,
  Terminal,
  Trash2,
  User,
  Users,
  UserPlus,
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
