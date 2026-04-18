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
  return s:gsub('^"', ""):gsub('"$', ""):gsub("^'", ""):gsub("'$", "")
end

local function join_fs(...)
  local parts = {...}
  local path = table.concat(parts, sep)
  return normalize_fs_path(path)
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
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

local function get_project_root()
  if quarto and quarto.project and quarto.project.directory then
    return normalize_fs_path(quarto.project.directory)
  end
  return "."
end

local function parse_yaml_front_matter(content)
  if not content then
    return nil
  end

  local yaml = content:match("^%-%-%-%s*\n(.-)\n%-%-%-%s*\n")
  if not yaml then
    return nil
  end

  local meta = {
    categories = {}
  }

  local current_key = nil

  for line in yaml:gmatch("[^\r\n]+") do
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
              table.insert(meta.categories, trim(strip_quotes(cat)))
            end
          end
        end
      end
    else
      local item = line:match("^%s*%-%s*(.-)%s*$")
      if item and current_key == "categories" then
        table.insert(meta.categories, trim(strip_quotes(item)))
      end
    end
  end

  return meta
end

local function category_set(categories)
  local set = {}
  for _, c in ipairs(categories or {}) do
    set[c:lower()] = true
  end
  return set
end

local function overlap_score(a, b)
  local sa = category_set(a)
  local score = 0
  for _, c in ipairs(b or {}) do
    if sa[c:lower()] then
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

local function list_collection_index_files(project_root, collection)
  local files = {}
  local collection_root = join_fs(project_root, collection)

  local cmd
  if sep == "\\" then
    cmd = 'cmd /c dir /b /ad "' .. collection_root .. '"'
  else
    cmd = 'find "' .. collection_root .. '" -mindepth 1 -maxdepth 1 -type d'
  end

  local p = io.popen(cmd)
  if not p then
    return files
  end

  for line in p:lines() do
    local dir_name = trim(line)
    if dir_name ~= "" then
      local full_dir

      if sep == "\\" then
        full_dir = join_fs(collection_root, dir_name)
      else
        if dir_name:match("^" .. normalize_web_path(collection_root) .. "/") then
          full_dir = normalize_fs_path(dir_name)
        else
          full_dir = join_fs(collection_root, dir_name)
        end
      end

      local index_path = join_fs(full_dir, "index.qmd")
      if file_exists(index_path) then
        table.insert(files, index_path)
      end
    end
  end

  p:close()
  return files
end

local function collect_related(project_root, current_key, current_meta, collection)
  local files = list_collection_index_files(project_root, collection)
  local related = {}

  for _, file in ipairs(files) do
    local key = canonical_key(file)

    if key and key ~= current_key then
      local meta = parse_yaml_front_matter(read_file(file))
      if meta and meta.title and meta.categories and #meta.categories > 0 then
        local score = overlap_score(current_meta.categories, meta.categories)
        if score > 0 then
          table.insert(related, {
            key = key,
            title = meta.title,
            href = href_from_key(key),
            description = meta.description,
            date = meta.date or "",
            score = score
          })
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

  return related
end

local function append_related_section(doc, heading, items, max_items)
  if not items or #items == 0 then
    return
  end

  local n = math.min(max_items or 4, #items)

  table.insert(doc.blocks, pandoc.Header(2, heading))

  for i = 1, n do
    local item = items[i]

    table.insert(doc.blocks, pandoc.Para({
      pandoc.Link(item.title, item.href)
    }))

    if item.description and item.description ~= "" then
      table.insert(doc.blocks, pandoc.Para({
        pandoc.Str(item.description)
      }))
    end
  end
end

function Pandoc(doc)
  local input_file = quarto.doc.input_file
  if not input_file then
    return doc
  end

  local project_root = get_project_root()
  local current_abs = join_fs(project_root, input_file)
  local current_key = canonical_key(input_file)

  if not current_key then
    return doc
  end

  local current_meta = parse_yaml_front_matter(read_file(current_abs))
  if not current_meta or not current_meta.categories or #current_meta.categories == 0 then
    return doc
  end

  local related_longforms = collect_related(project_root, current_key, current_meta, "longforms")
  local related_posts = collect_related(project_root, current_key, current_meta, "posts")

  append_related_section(doc, "See also longforms", related_longforms, 4)
  append_related_section(doc, "See also posts", related_posts, 4)

  return doc
end