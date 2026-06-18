## jekyll-jtd-toc-nav

A drop-in Jekyll plugin that injects the current page’s heading outline into the **Just the Docs** sidebar navigation (as nested `nav-list` items). Add the plugin to your site and it runs automatically.

<img width="640" height="360" alt="toc-nav-demo-1" src="https://github.com/user-attachments/assets/19b1606a-288d-4253-bd9a-ddf43c1a05be" />

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
```

### Options

- `sidebar_toc_levels`: heading levels to include (default `"2..4"`)
- `sidebar_toc_expand`: expand all outline sections by default (default `true`; set to `false` to start collapsed)
