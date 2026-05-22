# jekyll-jtd-toc-nav — feature reference

This document lists what the gem does, how it integrates with **Just the Docs**, and configuration options. Behavior matches the current implementation in `lib/jekyll/jtd_toc_nav/injector.rb`.

---

## Purpose

After each page or document is rendered to HTML, the plugin **injects a nested table-of-contents outline** (based on in-page headings) into the **sidebar** under the nav item for **that same page**. Outline items use the same markup as JTD (`ul.nav-list`, `li.nav-list-item`, `a.nav-list-link`, and `button.nav-list-expander` where needed) so the theme’s CSS and JavaScript continue to apply.

---

## When it runs

| Aspect | Detail |
|--------|--------|
| **Hook** | `:post_render` on **`:pages`** and **`:documents`** (collection entries). |
| **Timing** | After Jekyll has produced `page.output` (HTML string), before the site is written out. |
| **Idempotency** | On each run, any previously injected outline (`ul.nav-list[data-jtd-toc-nav="true"]` that is a **direct child** of the current page’s `li.nav-list-item`) is removed and rebuilt. |

---

## Activation

If the plugin is listed under `plugins:` (and loaded via the Gemfile), injection runs on every eligible page. There is no separate on/off flag.

---

## Configuration options

| Key | Purpose | Default / notes |
|-----|---------|-----------------|
| `sidebar_toc_levels` | Which heading levels to include. | Defaults to **h2–h4** if omitted. |
| `sidebar_toc_expand` | Add class `active` to outline items that have sub-headings so nested sections start expanded. | `true` if unset; set to `false` to start collapsed. |

**Heading levels format**

- Omitted → levels **2 through 4** (inclusive).
- String with `..` (e.g. `"2..6"`) → inclusive range of integers; invalid values fall back to default.
- Array of integers → use only those levels (e.g. `[2, 3, 5]`); empty/invalid falls back to default.

---

## Heading collection (what appears in the sidebar)

Headings are gathered with a CSS selector built from configured levels, always under **`main`**:

- Example default: `main h2, main h3, main h4`

**Included**

- Headings with a **non-empty `id`** attribute (used for `#fragment` links in the outline).
- Headings whose level is in the configured set.

**Excluded**

- Headings missing an `id`.
- Headings with class **`no_toc`**.
- Headings inside a content TOC wrapper: ancestor has **`id="markdown-toc"`** or includes class **`js-page-toc`** (avoids duplicating headings that are already part of an in-page table of contents).

---

## Sidebar placement (which nav item gets the outline)

1. Parses rendered HTML and finds **`#site-nav`** — required; if missing, nothing is injected (JTD is expected).
2. Resolves **`page_like.url`** to the **`a.nav-list-link`** inside `#site-nav` that points at that page.
3. **URL matching** tries several candidates to align with typical Jekyll / JTD output:
   - The page URL as given
   - Same URL with a trailing `/`
   - Same URL with `.html` suffix (when not already ending in `.html`)
   - Each of the above **with and without** `baseurl` from `_config.yml` (when `baseurl` is set and not just `/`)

**Selector safety:** `href` values are minimally escaped for use inside a CSS attribute selector (backslashes and double quotes).

4. Finds the enclosing **`li.nav-list-item`** for that link. The outline `<ul>` is appended as an additional **direct child** of that `<li>` (alongside the page link subtree).

If no matching link or no `li.nav-list-item` ancestor is found, injection is skipped silently for that page.

---

## Injected markup

- **`ul.nav-list`** with **`data-jtd-toc-nav="true"`** — marks the injected block (and supports cleanup on re-render).
- For each heading, a **`li.nav-list-item`** containing an **`a.nav-list-link`** with:
  - `href="##{id}"` (in-page anchor to the heading).
  - Link text from the trimmed heading text.

**Nesting**

- Outline structure follows heading levels (outline tree built from a stack over the flat heading list).
- If headings skip a level (e.g. `h2` then `h4`), the builder **treats the deeper heading as nesting under the current parent** effectively (intermediate logical levels are “filled” in the stack sense).

---

## Expand/collapse (JTD-native)

**Page row (current page in sidebar)**

- A **`button.nav-list-expander`** is ensured on the **`li`** for the current page (label: “Toggle page sections”) so nested outline lists behave like other JTD expandable nav items.

**Outline rows**

- **`button.nav-list-expander`** is added **only for headings that have sub-headings** (i.e. a later heading exists at a **deeper level**).
- Leaf headings **do not** get an expander (no meaningless arrow for sections with no children).
- When **`sidebar_toc_expand`** is enabled (default), each branch item with children also gets class **`active`** so its nested list is visible on load.

Expander markup matches JTD: `btn-reset`, SVG using `#svg-arrow-right`, `aria-label`, and `aria-expanded` derived from whether the **`li`** already has class **`active`**.

**Important:** Sidebar open/close for nested lists is governed by **Just the Docs’ own JavaScript**, which listens for clicks on **`nav-list-expander`**, not necessarily for clicks on the link text alone.

---

## Current page highlighting

After injection, the **`li.nav-list-item`** for the active page receives class **`active`**, consistent with expanded/open nav styling expectations.

---

## Error handling

If parsing or mutation raises, the gem **rescues**, logs a **warning** prefixed with **`jtd-toc-nav:`** (includes page URL and error class/message), and does not abort the whole build.

---

## Performance detail

One **`Injector`** instance per site build is memoized under `site.config["__jtd_toc_nav_injector"]` so it is reused for every `:post_render` call.

---

## Requirements (implicit)

- **Jekyll** (plugin loads `jekyll` and registers hooks).
- **Nokogiri** (HTML parse and mutate).
- A **Just-the-Docs-shaped** sidebar: **`#site-nav`**, **`a.nav-list-link`**, **`li.nav-list-item`**.
- Pages must render **meaningful `<main>...</main>` with headed sections** (`id`-bearing headings in configured levels).

---

## What this gem does **not** do

- Does not ship or inject separate JavaScript for custom link-click behaviors; expansion uses JTD’s stock behavior after matching markup is injected.
- Does not alter front matter, collections, or how JTD builds `_config.yml` navigation — it only tweaks **post-render HTML** per page/document.
