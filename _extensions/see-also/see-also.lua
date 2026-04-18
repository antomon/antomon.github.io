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

local function is_language_tag(s)
  return s == "🇬🇧" or s == "🇮🇹"
end

local function normalize_category(s)
  s = pandoc.text.lower(s or "")
  s = trim(s)
  s = s:gsub("%s+", " ")
  return s
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
    description = nil,
    image = nil,
    categories = {}
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
      elseif key == "description" then
        meta.description = strip_quotes(value)
      elseif key == "image" then
        meta.image = strip_quotes(value)
      elseif key == "categories" then
        if value ~= "" then
          local inline = value:match("^%[(.*)%]$")
          if inline then
            for cat in inline:gmatch("[^,]+") do
              local c = normalize_category(strip_quotes(cat))
              if c ~= "" and not is_language_tag(c) then
                table.insert(meta.categories, c)
              end
            end
          end
        end
      end
    else
      local item = line:match("^%s*%-%s*(.-)%s*$")
      if item and current_key == "categories" then
        local c = normalize_category(strip_quotes(item))
        if c ~= "" and not is_language_tag(c) then
          table.insert(meta.categories, c)
        end
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
            table.insert(related, {
              title = meta.title,
              subtitle = meta.subtitle,
              href = href_from_key(key),
              date = meta.date or "",
              date_modified = meta.date_modified or "",
              score = score
            })
          end
        end
      end
    end
  end

  table.sort(related, function(x, y)
    local x_sort = x.date_modified ~= "" and x.date_modified or x.date
    local y_sort = y.date_modified ~= "" and y.date_modified or y.date

    if x_sort ~= y_sort then
      return x_sort > y_sort
    end

    if x.score ~= y.score then
      return x.score > y.score
    end

    return x.title < y.title
  end)

  return related
end

local function render_cards_html(heading, items, max_items)
  if not items or #items == 0 then
    return nil
  end

  local n = math.min(max_items or 4, #items)
  local html = {}

  table.insert(html, '<section class="see-also-section">')
  table.insert(html, '<h2>' .. html_escape(heading) .. '</h2>')
  table.insert(html, '<div class="see-also-grid">')

  for i = 1, n do
    local item = items[i]
    table.insert(html, '<article class="see-also-card card h-100">')
    table.insert(html, '<a class="see-also-card-link" href="' .. html_escape(item.href) .. '">')
    table.insert(html, '<div class="card-body">')
    table.insert(html, '<h5 class="card-title see-also-card-title">' .. html_escape(item.title) .. '</h5>')

    if item.subtitle and trim(item.subtitle) ~= "" then
      table.insert(html,
        '<div class="card-subtitle see-also-card-subtitle">' .. html_escape(item.subtitle) .. '</div>'
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

local function append_related_section(doc, heading, items, max_items)
  local html = render_cards_html(heading, items, max_items)
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
  if not current_meta or not current_meta.categories or #current_meta.categories == 0 then
    return doc
  end

  local current_categories = current_meta.categories

  local related_longforms = collect_related(project_root, current_key, current_categories, "longforms")
  local related_posts = collect_related(project_root, current_key, current_categories, "posts")

  append_related_section(doc, "See also longforms", related_longforms, 4)
  append_related_section(doc, "See also posts", related_posts, 4)

  return doc
end