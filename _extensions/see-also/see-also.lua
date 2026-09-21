local sep = package.config:sub(1,1)

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize_fs_path(path)
  if sep == "\\" then
    return path:gsub("/", "\\")
  else
    return path:gsub("\\", "/")
  end
end

local function normalize_web_path(path)
  return path:gsub("\\", "/")
end

local function strip_quotes(s)
  s = trim(s or "")
  return s:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
end

local function join_fs(...)
  local parts = {...}
  local path = table.concat(parts, sep)
  return normalize_fs_path(path)
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function is_directory(path)
  local ok, entries = pcall(pandoc.system.list_directory, path)
  return ok and type(entries) == "table"
end

local function get_project_root()
  if quarto and quarto.project and quarto.project.directory then
    return normalize_fs_path(quarto.project.directory)
  end
  return normalize_fs_path(".")
end

local function normalize_category(s)
  s = pandoc.text.lower(s or "")
  s = trim(s)
  s = s:gsub("%s+", " ")
  return s
end

-- Editorial-form labels are ordinary Quarto categories, but they are not
-- topical categories and therefore must not affect related-content/topic
-- similarity. Report is the default form; position paper is retained here as
-- a legacy editorial label during migration.
local editorial_form_categories = {
  ["essay"] = true,
  ["tutorial"] = true,
  ["review"] = true,
  ["report"] = true,
  ["position paper"] = true,
}

local excluded_categories = {
  ["🇬🇧"] = true,
  ["🇮🇹"] = true,
}

for category, _ in pairs(editorial_form_categories) do
  excluded_categories[category] = true
end

local function is_excluded_category(s)
  s = normalize_category(s or "")
  return excluded_categories[s] == true
end

local function extract_front_matter(content)
  if not content then
    return nil
  end

  content = content:gsub("\r\n", "\n")

  if not content:match("^%-%-%-\n") then
    return nil
  end

  local body = content:match("^%-%-%-\n(.-)\n%-%-%-\n")
  return body
end

local function add_category(meta, raw_category)
  local label = strip_quotes(raw_category or "")
  label = trim(label):gsub("%s+", " ")

  local key = normalize_category(label)
  if key == "" or is_excluded_category(key) then
    return
  end

  if not meta.category_labels[key] then
    meta.category_labels[key] = label
    table.insert(meta.categories, key)
  end
end

local function parse_yaml_front_matter(content)
  local yaml = extract_front_matter(content)
  if not yaml then
    return nil
  end

  local meta = {
    title = nil,
    subtitle = nil,
    date = nil,
    date_modified = nil,
    image = nil,
    series = nil,
    categories = {},
    category_labels = {}
  }

  local current_key = nil

  for line in yaml:gmatch("[^\n]+") do
    local key, value = line:match("^([%w_-]+):%s*(.-)%s*$")

    if key then
      current_key = key

      if key == "title" then
        meta.title = strip_quotes(value)
      elseif key == "subtitle" then
        meta.subtitle = strip_quotes(value)
      elseif key == "date" then
        meta.date = strip_quotes(value)
      elseif key == "date-modified" then
        meta.date_modified = strip_quotes(value)
      elseif key == "image" then
        meta.image = strip_quotes(value)
      elseif key == "series" then
        meta.series = strip_quotes(value)
        if trim(meta.series) == "" then
          meta.series = nil
        end
      elseif key == "categories" then
        if value ~= "" then
          local inline = value:match("^%[(.*)%]$")
          if inline then
            for cat in inline:gmatch("[^,]+") do
              add_category(meta, cat)
            end
          end
        end
      end
    else
      local item = line:match("^%s*%-%s*(.-)%s*$")
      if item and current_key == "categories" then
        add_category(meta, item)
      end
    end
  end

  return meta
end

local function category_set(categories)
  local set = {}
  for _, c in ipairs(categories or {}) do
    if c ~= "" then
      set[c] = true
    end
  end
  return set
end

local function overlap_score(a, b)
  local sa = category_set(a)
  local score = 0
  for _, c in ipairs(b or {}) do
    if sa[c] then
      score = score + 1
    end
  end
  return score
end

local function has_category(categories, target_category)
  for _, category in ipairs(categories or {}) do
    if category == target_category then
      return true
    end
  end
  return false
end

local function canonical_key(path)
  local p = normalize_web_path(path)

  local rel = p:match("(^posts/[^/]+/index%.qmd$)")
  if rel then
    return rel
  end

  rel = p:match("(^longforms/[^/]+/index%.qmd$)")
  if rel then
    return rel
  end

  rel = p:match("(posts/[^/]+/index%.qmd)$")
  if rel then
    return rel
  end

  rel = p:match("(longforms/[^/]+/index%.qmd)$")
  if rel then
    return rel
  end

  return nil
end

local function href_from_key(key)
  local p = normalize_web_path(key)
  p = p:gsub("/index%.qmd$", "/")
  return "/" .. p
end

local function image_href_from_key_and_meta(key, meta)
  if not meta.image or trim(meta.image) == "" then
    return nil
  end

  local base = href_from_key(key)
  if base:sub(-1) ~= "/" then
    base = base .. "/"
  end

  return base .. meta.image
end

local function resolve_input_path(project_root, input_file)
  input_file = normalize_fs_path(input_file)

  if sep == "\\" then
    if input_file:match("^[A-Za-z]:\\") then
      return input_file
    end
  else
    if input_file:match("^/") then
      return input_file
    end
  end

  return join_fs(project_root, input_file)
end

local function list_collection_index_files(project_root, collection)
  local files = {}
  local collection_root = join_fs(project_root, collection)

  local ok, entries = pcall(pandoc.system.list_directory, collection_root)
  if not ok or type(entries) ~= "table" then
    return files
  end

  for _, entry in ipairs(entries) do
    if entry ~= "." and entry ~= ".." then
      local subdir = join_fs(collection_root, entry)
      if is_directory(subdir) then
        local index_path = join_fs(subdir, "index.qmd")
        if file_exists(index_path) then
          table.insert(files, index_path)
        end
      end
    end
  end

  return files
end

local function html_escape(s)
  s = s or ""
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  return s
end

local function slugify_series(title)
  local slug = pandoc.text.lower(trim(title or ""))
  slug = slug:gsub("['’]", "")
  slug = slug:gsub("[^a-z0-9]+", "-")
  slug = slug:gsub("%-+", "-")
  slug = slug:gsub("^%-", ""):gsub("%-$", "")
  return slug
end

local function render_series_title_meta(series_title, placement_heading)
  local slug = slugify_series(series_title)
  if slug == "" then
    return nil
  end

  local href = "/series/" .. slug .. "/"

  return [[
<div id="article-series-meta-source"
     data-series-title="]] .. html_escape(series_title) .. [["
     data-series-href="]] .. html_escape(href) .. [["
     data-series-after="]] .. html_escape(placement_heading or "") .. [["
     hidden></div>
<script>
(function () {
  const source = document.getElementById("article-series-meta-source");
  const meta = document.querySelector("#title-block-header .quarto-title-meta");

  if (!source || !meta) {
    if (source) source.remove();
    return;
  }

  const headings = Array.from(meta.querySelectorAll(".quarto-title-meta-heading"));

  // Defensive: do not add a duplicate if another template/filter already did.
  if (headings.some((el) => el.textContent.trim().toLowerCase() === "series")) {
    source.remove();
    return;
  }

  const item = document.createElement("div");

  const heading = document.createElement("div");
  heading.className = "quarto-title-meta-heading";
  heading.textContent = "Series";

  const contents = document.createElement("div");
  contents.className = "quarto-title-meta-contents";

  const paragraph = document.createElement("p");
  paragraph.className = "series";

  const link = document.createElement("a");
  link.href = source.dataset.seriesHref;
  link.textContent = source.dataset.seriesTitle;

  paragraph.appendChild(link);
  contents.appendChild(paragraph);
  item.appendChild(heading);
  item.appendChild(contents);

  // Placement differs between posts and longforms.
  // Posts: after READING TIME.
  // Longforms: after KEYWORDS.
  const targetLabel = (source.dataset.seriesAfter || "").trim().toLowerCase();
  const targetHeading = headings.find(
    (el) => el.textContent.trim().toLowerCase() === targetLabel
  );
  const targetItem = targetHeading ? targetHeading.parentElement : null;

  if (targetItem && targetItem.parentElement === meta) {
    targetItem.insertAdjacentElement("afterend", item);
  } else {
    // Defensive fallback if a title-block variant does not expose the
    // expected metadata heading.
    meta.appendChild(item);
  }

  source.remove();
})();
</script>
]]
end

local function url_encode_component(s)
  return (s or ""):gsub("([^%w%-_%.~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
end

local function sort_related_by_modified_date(related, use_score_tiebreaker)
  table.sort(related, function(x, y)
    local x_sort = x.date_modified ~= "" and x.date_modified or x.date
    local y_sort = y.date_modified ~= "" and y.date_modified or y.date

    if x_sort ~= y_sort then
      return x_sort > y_sort
    end

    if use_score_tiebreaker and x.score ~= y.score then
      return x.score > y.score
    end

    return x.title < y.title
  end)
end

local function related_item(key, meta, score)
  return {
    title = meta.title,
    subtitle = meta.subtitle,
    href = href_from_key(key),
    image = image_href_from_key_and_meta(key, meta),
    date = meta.date or "",
    date_modified = meta.date_modified or "",
    score = score or 0
  }
end

local function collect_related(project_root, current_key, current_categories, collection)
  local files = list_collection_index_files(project_root, collection)
  local related = {}

  for _, file in ipairs(files) do
    local key = canonical_key(file)

    if key and key ~= current_key then
      local content = read_file(file)
      if content then
        local meta = parse_yaml_front_matter(content)
        if meta and meta.title and trim(meta.title) ~= "" and meta.categories and #meta.categories > 0 then
          local score = overlap_score(current_categories, meta.categories)

          if score > 0 then
            table.insert(related, related_item(key, meta, score))
          end
        end
      end
    end
  end

  -- Posts remain ordered primarily by date-modified descending.
  -- The publication date is used only when date-modified is absent.
  sort_related_by_modified_date(related, true)

  return related
end

local function collect_related_longforms_for_category(project_root, current_key, category)
  local files = list_collection_index_files(project_root, "longforms")
  local related = {}

  for _, file in ipairs(files) do
    local key = canonical_key(file)

    if key and key ~= current_key then
      local content = read_file(file)
      if content then
        local meta = parse_yaml_front_matter(content)
        if meta
          and meta.title
          and trim(meta.title) ~= ""
          and meta.categories
          and has_category(meta.categories, category)
        then
          table.insert(related, related_item(key, meta, 0))
        end
      end
    end
  end

  sort_related_by_modified_date(related, false)

  return related
end

local function sorted_current_categories(meta)
  local categories = {}

  for _, key in ipairs(meta.categories or {}) do
    table.insert(categories, {
      key = key,
      label = meta.category_labels[key] or key
    })
  end

  table.sort(categories, function(x, y)
    if x.key ~= y.key then
      return x.key < y.key
    end
    return x.label < y.label
  end)

  return categories
end

local function longform_heading_html(category)
  local href = "https://4m4.it/index.html#category=" .. url_encode_component(category.label)

  return 'See also <a href="'
    .. html_escape(href)
    .. '">'
    .. html_escape(category.label)
    .. '</a> longforms'
end

local function render_cards_html(heading, items, max_items, heading_is_html)
  if not items or #items == 0 then
    return nil
  end

  local n = math.min(max_items or 4, #items)
  local html = {}

  table.insert(html, [[
<section class="see-also-inline-block" style="margin-top:2.75rem;">
  <style>
    .see-also-inline-block .see-also-cards {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 1rem;
      margin-top: 1rem;
    }

    .see-also-inline-block .see-also-card {
      overflow: hidden;
      border: 1px solid rgba(0,0,0,0.08);
      border-radius: 14px;
      background: var(--bs-body-bg);
      box-shadow: 0 2px 8px rgba(0,0,0,0.04);
      height: 100%;
    }

    .see-also-inline-block .see-also-card-link {
      color: inherit;
      text-decoration: none;
      display: block;
      height: 100%;
    }

    .see-also-inline-block .see-also-card-link:hover {
      color: inherit;
      text-decoration: none;
    }

    .see-also-inline-block .see-also-card-image {
      width: 100%;
      height: 160px;
      object-fit: cover;
      display: block;
    }

    .see-also-inline-block .see-also-card-body {
      padding: 1rem;
    }

    .see-also-inline-block .see-also-card-title {
      margin: 0 0 0.45rem 0;
      line-height: 1.25;
      font-size: 1.1rem;
    }

    .see-also-inline-block .see-also-card-subtitle {
      color: var(--bs-secondary-color, #6c757d);
      font-size: 0.95rem;
      line-height: 1.35;
    }

    @media (max-width: 991px) {
      .see-also-inline-block .see-also-cards {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }
    }

    @media (max-width: 575px) {
      .see-also-inline-block .see-also-cards {
        grid-template-columns: 1fr;
      }
    }
  </style>
]])

  local rendered_heading = heading_is_html and heading or html_escape(heading)
  table.insert(html, '<h2>' .. rendered_heading .. '</h2>')
  table.insert(html, '<div class="see-also-cards">')

  for i = 1, n do
    local item = items[i]

    table.insert(html, '<article class="see-also-card">')
    table.insert(html, '<a class="see-also-card-link" href="' .. html_escape(item.href) .. '">')

    if item.image and trim(item.image) ~= "" then
      table.insert(html,
        '<img class="see-also-card-image" src="' .. html_escape(item.image) .. '" alt="">'
      )
    end

    table.insert(html, '<div class="see-also-card-body">')
    table.insert(html, '<h5 class="see-also-card-title">' .. html_escape(item.title) .. '</h5>')

    if item.subtitle and trim(item.subtitle) ~= "" then
      table.insert(html,
        '<div class="see-also-card-subtitle">' .. html_escape(item.subtitle) .. '</div>'
      )
    end

    table.insert(html, '</div>')
    table.insert(html, '</a>')
    table.insert(html, '</article>')
  end

  table.insert(html, '</div>')
  table.insert(html, '</section>')

  return table.concat(html, "\n")
end

local function append_related_section(doc, heading, items, max_items, heading_is_html)
  local html = render_cards_html(heading, items, max_items, heading_is_html)
  if not html then
    return
  end

  table.insert(doc.blocks, pandoc.RawBlock("html", html))
end

function Pandoc(doc)
  local input_file = quarto.doc.input_file
  if not input_file then
    return doc
  end

  local current_key = canonical_key(input_file)
  if not current_key then
    return doc
  end

  local project_root = get_project_root()
  local input_path = resolve_input_path(project_root, input_file)
  local current_content = read_file(input_path)

  if not current_content then
    return doc
  end

  local current_meta = parse_yaml_front_matter(current_content)
  if not current_meta then
    return doc
  end

  -- Series is independent of category-based "See also" logic.
  -- If present, render it in the Quarto title metadata immediately after
  -- Reading Time. Articles without a series keep the existing title block.
  if current_meta.series and trim(current_meta.series) ~= "" then
    local placement_heading = "Reading Time"
    if current_key:match("^longforms/") then
      placement_heading = "Keywords"
    end

    local series_meta_html = render_series_title_meta(
      current_meta.series,
      placement_heading
    )
    if series_meta_html then
      table.insert(doc.blocks, pandoc.RawBlock("html", series_meta_html))
    end
  end

  if not current_meta.categories or #current_meta.categories == 0 then
    return doc
  end

  local current_categories = current_meta.categories
  local ordered_categories = sorted_current_categories(current_meta)

  for _, category in ipairs(ordered_categories) do
    local related_longforms = collect_related_longforms_for_category(
      project_root,
      current_key,
      category.key
    )

    append_related_section(
      doc,
      longform_heading_html(category),
      related_longforms,
      3,
      true
    )
  end

  local related_posts = collect_related(
    project_root,
    current_key,
    current_categories,
    "posts"
  )

  append_related_section(doc, "See also posts", related_posts, 6, false)

  return doc
end