## jekyll-jtd-toc-nav

A drop-in Jekyll plugin that injects the current page’s heading outline into the **Just the Docs** sidebar navigation (as nested `nav-list` items). It also injects a small inline script so clicking a heading in the injected outline expands/collapses its immediate children.

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
- `sidebar_toc_expand`: deprecated (no longer used)
