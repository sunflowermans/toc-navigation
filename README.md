## jekyll-jtd-toc-nav

A **drop-in** Jekyll plugin that injects the current page’s heading outline into the **Just the Docs** sidebar navigation (as nested `nav-list` items), without requiring users to override theme HTML or JS.

### Install

In your site `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-jtd-toc-nav"
end
```

In `_config.yml`:

```yml
plugins:
  - jekyll-jtd-toc-nav

sidebar_toc: true
```

### Options

- `sidebar_toc` (boolean): enable injection (default `false`)
- `sidebar_toc_levels`: heading levels to include (default `"2..4"`)
- `sidebar_toc_expand`: expand nested sections by default (default `true`)

Aliases (also accepted):
- `jtd_toc_nav` / `jtd_toc_nav_levels` / `jtd_toc_nav_expand`

