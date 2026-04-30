# frozen_string_literal: true

module Jekyll
  module JtdTocNav
    class Injector
      DEFAULT_LEVELS = (2..4).to_a

      def initialize(site:)
        @site = site
      end

      def enabled?
        @site.config.fetch("sidebar_toc", false) == true ||
          @site.config.fetch("jtd_toc_nav", false) == true
      end

      def levels
        raw = @site.config["sidebar_toc_levels"] || @site.config["jtd_toc_nav_levels"]
        return DEFAULT_LEVELS if raw.nil?

        if raw.is_a?(String) && raw.include?("..")
          a, b = raw.split("..", 2).map { |x| Integer(x) rescue nil }
          return DEFAULT_LEVELS if a.nil? || b.nil?
          return (a..b).to_a
        end

        if raw.is_a?(Array)
          ints = raw.map { |x| Integer(x) rescue nil }.compact
          return DEFAULT_LEVELS if ints.empty?
          return ints
        end

        DEFAULT_LEVELS
      end

      def expand_by_default?
        @site.config.fetch("sidebar_toc_expand", true) != false &&
          @site.config.fetch("jtd_toc_nav_expand", true) != false
      end

      def process!(page_like)
        return unless enabled?
        return if page_like.output.nil? || page_like.output.empty?

        html = page_like.output
        doc = Nokogiri::HTML(html)

        headings = extract_headings(doc)
        return if headings.empty?

        nav = doc.at_css("#site-nav")
        return unless nav

        page_url = page_like.url
        link = find_nav_link(nav, page_url)
        return unless link

        nav_item = link.ancestors("li.nav-list-item").first
        return unless nav_item

        # Remove any prior injection
        nav_item.css("> ul.nav-list[data-jtd-toc-nav='true']").remove

        outline_ul = build_outline_ul(doc, headings)
        outline_ul["data-jtd-toc-nav"] = "true"

        # Ensure current page can expand/collapse like other nav items.
        ensure_expander!(doc, nav_item, label: "Toggle page sections")
        ensure_outline_link_toggle_script!(doc)

        nav_item.add_class("active")
        nav_item.add_child(outline_ul)

        page_like.output = doc.to_html
      rescue StandardError => e
        Jekyll.logger.warn("jtd-toc-nav:", "failed to inject sidebar toc for #{page_like.url}: #{e.class}: #{e.message}")
      end

      private

      def extract_headings(doc)
        selector = levels.map { |lvl| "main h#{lvl}" }.join(", ")
        doc.css(selector).filter_map do |h|
          next if h["id"].to_s.empty?
          classes = h["class"].to_s.split(/\s+/)
          next if classes.include?("no_toc")
          # Dont pull headings from the TOC itself if it exists in content.
          next if h.ancestors.any? { |a| a["id"] == "markdown-toc" || a["class"].to_s.split(/\s+/).include?("js-page-toc") }

          {
            id: h["id"],
            text: h.text.strip,
            level: h.name.delete_prefix("h").to_i
          }
        end
      end

      def find_nav_link(nav, page_url)
        baseurl = @site.config["baseurl"].to_s
        baseurl = "" if baseurl == "/"

        # Match just-the-docs trailing slash / .html.
        candidates = []
        candidates << page_url
        candidates << "#{page_url}/" unless page_url.end_with?("/")
        candidates << "#{page_url}.html" unless page_url.end_with?(".html")
        candidates = candidates.uniq

        candidates = candidates.flat_map do |u|
          if baseurl.empty?
            [u]
          else
            [u, File.join(baseurl, u)]
          end
        end.uniq

        candidates.each do |href|
          link = nav.at_css(%(a.nav-list-link[href="#{css_escape(href)}"]))
          return link if link
        end

        nil
      end

      def css_escape(s)
        # Minimal escape for quotes/backslashes in attribute selectors.
        s.to_s.gsub("\\", "\\\\").gsub('"', '\"')
      end

      def build_outline_ul(doc, headings)
        min_level = headings.map { |h| h[:level] }.min
        stack = []

        root_ul = Nokogiri::XML::Node.new("ul", doc)
        root_ul["class"] = "nav-list"
        stack << { level: min_level - 1, ul: root_ul }

        headings.each_with_index do |h, idx|
          while stack.size > 1 && h[:level] <= stack.last[:level]
            stack.pop
          end

          while h[:level] > stack.last[:level] + 1
            # Skip missing intermediate levels by treating as direct child.
            stack.last[:level] += 1
          end

          li = Nokogiri::XML::Node.new("li", doc)
          li["class"] = "nav-list-item"

          a = Nokogiri::XML::Node.new("a", doc)
          a["class"] = "nav-list-link"
          a["href"] = "##{h[:id]}"
          a.content = h[:text]
          li.add_child(a)

          parent_ul = stack.last[:ul]
          parent_ul.add_child(li)

          next_h = headings[idx + 1]
          has_children = next_h && next_h[:level] > h[:level]
          next unless has_children

          # This heading has nested headings; create the nested list and expander.
          child_ul = Nokogiri::XML::Node.new("ul", doc)
          child_ul["class"] = "nav-list"
          li.add_child(child_ul)

          # jtd hides nested `.nav-list` by default.
          ensure_expander!(doc, li, label: "Toggle section")

          stack << { level: h[:level], ul: child_ul }
        end

        root_ul
      end

      def ensure_expander!(doc, li, label:)
        existing = li.at_css("> button.nav-list-expander")
        return existing if existing

        button = Nokogiri::XML::Node.new("button", doc)
        button["class"] = "nav-list-expander btn-reset"
        button["aria-label"] = label
        button["aria-expanded"] = li["class"].to_s.split(/\s+/).include?("active") ? "true" : "false"
        button.inner_html = '<svg viewBox="0 0 24 24" aria-hidden="true"><use xlink:href="#svg-arrow-right"></use></svg>'

        li.children.first.add_previous_sibling(button)
        button
      end

      def ensure_outline_link_toggle_script!(doc)
        return if doc.at_css("script[data-jtd-toc-nav-outline-toggle='true']")

        body = doc.at_css("body")
        return unless body

        script = Nokogiri::XML::Node.new("script", doc)
        script["data-jtd-toc-nav-outline-toggle"] = "true"
        script.content = <<~JS
          (function () {
            function setExpanded(li, expanded) {
              if (!li) return;
              if (expanded) li.classList.add("active");
              else li.classList.remove("active");

              var btn = li.querySelector(":scope > button.nav-list-expander");
              if (btn) btn.setAttribute("aria-expanded", expanded ? "true" : "false");
            }

            function collapseDescendants(li) {
              var descendants = li.querySelectorAll("li.nav-list-item.active");
              for (var i = 0; i < descendants.length; i++) {
                if (descendants[i] === li) continue;
                setExpanded(descendants[i], false);
              }
            }

            document.addEventListener("click", function (e) {
              if (e.defaultPrevented) return;
              if (e.button !== 0) return;
              if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

              var btn = e.target && e.target.closest ? e.target.closest("button.nav-list-expander") : null;
              if (btn) {
                var btnOutline = btn.closest("ul.nav-list[data-jtd-toc-nav='true']");
                if (!btnOutline) return;

                var btnLi = btn.closest("li.nav-list-item");
                if (!btnLi) return;

                var btnChildUl = btnLi.querySelector(":scope > ul.nav-list");
                if (!btnChildUl) return;

                e.preventDefault();
                e.stopPropagation();

                var btnIsExpanded = btnLi.classList.contains("active");
                var btnNextExpanded = !btnIsExpanded;
                setExpanded(btnLi, btnNextExpanded);
                collapseDescendants(btnLi);
                return;
              }

              var a = e.target && e.target.closest ? e.target.closest("a.nav-list-link") : null;
              if (!a) return;

              var outline = a.closest("ul.nav-list[data-jtd-toc-nav='true']");
              if (!outline) return;

              var href = a.getAttribute("href") || "";
              if (href.charAt(0) !== "#") return;

              var li = a.closest("li.nav-list-item");
              if (!li) return;

              var childUl = li.querySelector(":scope > ul.nav-list");
              if (!childUl) return;

              // Clicking the header text should only expand (never collapse).
              if (li.classList.contains("active")) return;
              setExpanded(li, true);
              collapseDescendants(li);
            }, true);
          })();
        JS

        body.add_child(script)
      end
    end
  end
end

Jekyll::Hooks.register([:pages, :documents], :post_render) do |page, payload|
  # Jekyll 3.x hook signature may pass `payload` as nil.
  site = page.respond_to?(:site) ? page.site : nil
  site ||= payload.is_a?(Hash) ? payload["site"] : nil
  next unless site

  injector = site.config["__jtd_toc_nav_injector"] ||= Jekyll::JtdTocNav::Injector.new(site: site)
  injector.process!(page)
end

