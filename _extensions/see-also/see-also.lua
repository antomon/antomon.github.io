local sep = package.config:sub(1,1)

local function log(msg)
  if quarto and quarto.log and quarto.log.output then
    quarto.log.output("[see-also] " .. tostring(msg))
  end
end

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
    date = nil,
    description = nil,
    categories = {}
  }

  local current_key = nil

  for line in yaml:gmatch("[^\n]+") do
    local key, value = line:match("^([%w_-]+):%s*(.-)%s*$")

    if key then
      current_key = key

      if key == "title" then
        meta.title = strip_quotes(value)
      elseif key == "date" then
        meta.date = strip_quotes(value)
      elseif key == "description" then
        meta.description = strip_quotes(value)
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

local function append_unique(out, seen, value)
  local c = normalize_category(value)
  if c ~= "" and not is_language_tag(c) and not seen[c] then
    seen[c] = true
    table.insert(out, c)
  end
end

local function meta_to_categories(meta_categories)
  local out = {}
  local seen = {}

  local function walk(x)
    if x == nil then
      return
    end

    local x_type = type(x)

    if x_type == "string" then
      append_unique(out, seen, x)
      return
    end

    if x_type ~= "table" then
      local s = pandoc.utils.stringify(x)
      append_unique(out, seen, s)
      return
    end

    if x.t == "MetaList" then
      for _, item in ipairs(x) do
        walk(item)
      end
      return
    end

    if x.t == "MetaInlines" or x.t == "MetaBlocks" or x.t == "Inlines" or x.t == "Blocks" then
      append_unique(out, seen, pandoc.utils.stringify(x))
      return
    end

    if x.t == "MetaString" or x.t == "MetaBool" then
      append_unique(out, seen, pandoc.utils.stringify(x))
      return
    end

    if x.t == "MetaMap" then
      append_unique(out, seen, pandoc.utils.stringify(x))
      return
    end

    if #x > 0 then
      for _, item in ipairs(x) do
        walk(item)
      end
      return
    end

    append_unique(out, seen, pandoc.utils.stringify(x))
  end

  walk(meta_categories)
  return out
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

  log("Scanning collection root: " .. collection_root)

  local ok, entries = pcall(pandoc.system.list_directory, collection_root)
  if not ok or type(entries) ~= "table" then
    log("Cannot list collection root: " .. collection_root)
    return files
  end

  for _, entry in ipairs(entries) do
    if entry ~= "." and entry ~= ".." then
      local subdir = join_fs(collection_root, entry)
      if is_directory(subdir) then
        local index_path = join_fs(subdir, "index.qmd")
        if file_exists(index_path) then
          table.insert(files, index_path)
          log("Found candidate file: " .. index_path)
        end
      end
    end
  end

  log("Collection " .. collection .. " candidate files count: " .. tostring(#files))
  return files
end

local function collect_related(project_root, current_key, current_categories, collection)
  local files = list_collection_index_files(project_root, collection)
  local related = {}

  log("Current key: " .. tostring(current_key))
  log("Current categories: " .. table.concat(current_categories, ", "))

  for _, file in ipairs(files) do
    local key = canonical_key(file)
    log("Processing file: " .. tostring(file))
    log("Canonical key: " .. tostring(key))

    if key and key ~= current_key then
      local content = read_file(file)
      if not content then
        log("Could not read file: " .. tostring(file))
      else
        local meta = parse_yaml_front_matter(content)
        if not meta then
          log("No parseable front matter: " .. tostring(file))
        else
          log("Parsed title: " .. tostring(meta.title))
          log("Parsed categories count: " .. tostring(#meta.categories))
          if #meta.categories > 0 then
            log("Parsed categories: " .. table.concat(meta.categories, ", "))
          end

          if meta.title and trim(meta.title) ~= "" and meta.categories and #meta.categories > 0 then
            local score = overlap_score(current_categories, meta.categories)
            log("Score versus current page: " .. tostring(score))

            if score > 0 then
              table.insert(related, {
                title = meta.title,
                href = href_from_key(key),
                description = meta.description,
                date = meta.date or "",
                score = score
              })
              log("Added related item: " .. tostring(meta.title))
            end
          end
        end
      end
    end
  end

  table.sort(related, function(x, y)
    if x.score ~= y.score then
      return x.score > y.score
    end
    return x.date > y.date
  end)

  log("Collection " .. collection .. " related matches count: " .. tostring(#related))
  return related
end

local function append_related_section(doc, heading, items, max_items)
  if not items or #items == 0 then
    return
  end

  table.insert(doc.blocks, pandoc.Header(2, heading))

  local n = math.min(max_items or 4, #items)
  local bullet_items = {}

  for i = 1, n do
    local item = items[i]
    local blocks = {
      pandoc.Plain({
        pandoc.Link(item.title, item.href)
      })
    }

    if item.description and item.description ~= "" then
      table.insert(blocks, pandoc.Plain({
        pandoc.Str(item.description)
      }))
    end

    table.insert(bullet_items, blocks)
  end

  table.insert(doc.blocks, pandoc.BulletList(bullet_items))
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
    log("Could not read current file: " .. tostring(input_path))
    return doc
  end

  local current_meta = parse_yaml_front_matter(current_content)
  if not current_meta or not current_meta.categories or #current_meta.categories == 0 then
    log("Current page has no parseable categories: " .. tostring(input_path))
    return doc
  end

  local current_categories = current_meta.categories

  log("Project root: " .. tostring(project_root))
  log("Input file: " .. tostring(input_file))
  log("Resolved input path: " .. tostring(input_path))
  log("Current key: " .. tostring(current_key))
  log("Current categories: " .. table.concat(current_categories, ", "))

  local related_longforms = collect_related(project_root, current_key, current_categories, "longforms")
  local related_posts = collect_related(project_root, current_key, current_categories, "posts")

  append_related_section(doc, "See also longforms", related_longforms, 4)
  append_related_section(doc, "See also posts", related_posts, 4)

  return doc
end