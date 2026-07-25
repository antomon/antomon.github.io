-- Build-time article counters for the homepage taxonomy buttons.
--
-- The filter scans longforms/**/index.qmd and posts/**/index.qmd,
-- reads their YAML categories, and replaces markers such as
--
--   <span data-article-count="longforms|essay"></span>
--
-- with an accessible numeric badge. It runs only while rendering the
-- project-root index.qmd, despite being registered as a project filter.

local sep = package.config:sub(1, 1)

local function trim(value)
  value = value or ""
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize_fs_path(path)
  path = path or ""
  if sep == "\\" then
    return path:gsub("/", "\\")
  end
  return path:gsub("\\", "/")
end

local function join_fs(...)
  local parts = { ... }
  return normalize_fs_path(table.concat(parts, sep))
end

local function path_key(path)
  local normalized = normalize_fs_path(path)
  if sep == "\\" then
    normalized = normalized:lower()
  end
  return normalized:gsub("[\\/]$", "")
end

local function is_absolute(path)
  path = normalize_fs_path(path)
  if sep == "\\" then
    return path:match("^[A-Za-z]:\\") ~= nil or path:match("^\\\\") ~= nil
  end
  return path:sub(1, 1) == "/"
end

local function get_project_root()
  if quarto and quarto.project and quarto.project.directory then
    return normalize_fs_path(quarto.project.directory)
  end
  return normalize_fs_path(".")
end

local function get_input_file()
  if quarto and quarto.doc and quarto.doc.input_file then
    return normalize_fs_path(quarto.doc.input_file)
  end

  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    return normalize_fs_path(PANDOC_STATE.input_files[1])
  end

  return nil
end

local function resolve_path(project_root, path)
  if is_absolute(path) then
    return normalize_fs_path(path)
  end
  return join_fs(project_root, path)
end

local function read_file(path)
  local file, error_message = io.open(path, "r")
  if not file then
    io.stderr:write("homepage-counts: cannot read ", path, ": ", error_message or "unknown error", "\n")
    return nil
  end

  local content = file:read("*a")
  file:close()
  return content
end

local function is_directory(path)
  local ok, entries = pcall(pandoc.system.list_directory, path)
  return ok and type(entries) == "table"
end

local function normalize_category(value)
  value = pandoc.text.lower(trim(value or ""))
  return value:gsub("%s+", " ")
end

local function extract_yaml(content)
  if not content then
    return nil
  end

  content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
  if not content:match("^%-%-%-\n") then
    return nil
  end

  return content:match("^%-%-%-\n(.-)\n%-%-%-%s*\n")
end

local function metadata_from_file(path)
  local content = read_file(path)
  local yaml = extract_yaml(content)
  if not yaml then
    return nil
  end

  local ok, parsed = pcall(
    pandoc.read,
    "---\n" .. yaml .. "\n---\n",
    "markdown"
  )

  if not ok or not parsed then
    io.stderr:write("homepage-counts: cannot parse YAML in ", path, "\n")
    return nil
  end

  local metadata = parsed.meta or {}
  local draft = normalize_category(pandoc.utils.stringify(metadata.draft or ""))
  if draft == "true" or draft == "yes" or draft == "1" then
    return { draft = true, categories = {} }
  end

  local categories = {}
  local raw_categories = metadata.categories

  if raw_categories then
    local metadata_type = pandoc.utils.type(raw_categories)

    if metadata_type == "MetaList" or metadata_type == "List" then
      for _, category in ipairs(raw_categories) do
        local normalized = normalize_category(pandoc.utils.stringify(category))
        if normalized ~= "" then
          categories[normalized] = true
        end
      end
    else
      local scalar = trim(pandoc.utils.stringify(raw_categories))
      if scalar ~= "" then
        -- Support a scalar category and a defensive comma-separated scalar.
        local found_comma = scalar:find(",", 1, true) ~= nil
        if found_comma then
          for category in scalar:gmatch("[^,]+") do
            local normalized = normalize_category(category)
            if normalized ~= "" then
              categories[normalized] = true
            end
          end
        else
          categories[normalize_category(scalar)] = true
        end
      end
    end
  end

  return { draft = false, categories = categories }
end

local skipped_directories = {
  [".git"] = true,
  [".quarto"] = true,
  ["_freeze"] = true,
  ["_site"] = true,
  ["docs"] = true,
  ["node_modules"] = true,
}

local function collect_article_files(collection_root)
  local files = {}

  local function walk(directory)
    local ok, entries = pcall(pandoc.system.list_directory, directory)
    if not ok or type(entries) ~= "table" then
      return
    end

    table.sort(entries)

    for _, entry in ipairs(entries) do
      if entry ~= "." and entry ~= ".." and not skipped_directories[entry] then
        local path = join_fs(directory, entry)

        if is_directory(path) then
          walk(path)
        elseif entry == "index.qmd" and path_key(path) ~= path_key(join_fs(collection_root, "index.qmd")) then
          table.insert(files, path)
        end
      end
    end
  end

  if is_directory(collection_root) then
    walk(collection_root)
  end

  return files
end

local function scan_collection(project_root, collection)
  local statistics = {
    total = 0,
    categories = {},
  }

  local collection_root = join_fs(project_root, collection)
  for _, path in ipairs(collect_article_files(collection_root)) do
    local metadata = metadata_from_file(path)

    if metadata and not metadata.draft then
      statistics.total = statistics.total + 1

      for category, _ in pairs(metadata.categories) do
        statistics.categories[category] = (statistics.categories[category] or 0) + 1
      end
    end
  end

  return statistics
end

local function build_counts(project_root)
  local longforms = scan_collection(project_root, "longforms")
  local posts = scan_collection(project_root, "posts")
  local counts = {
    ["total|longforms"] = longforms.total,
    ["total|posts"] = posts.total,
  }

  local all_categories = {}

  for category, count in pairs(longforms.categories) do
    counts["longforms|" .. category] = count
    all_categories[category] = true
  end

  for category, count in pairs(posts.categories) do
    counts["posts|" .. category] = count
    all_categories[category] = true
  end

  for category, _ in pairs(all_categories) do
    counts["all|" .. category] =
      (longforms.categories[category] or 0) +
      (posts.categories[category] or 0)
  end

  return counts
end

local function normalize_count_key(key)
  local scope, value = trim(key):match("^([^|]+)|(.+)$")
  if not scope or not value then
    return trim(key)
  end

  scope = normalize_category(scope)
  if scope == "total" then
    value = normalize_category(value)
  else
    value = normalize_category(value)
  end

  return scope .. "|" .. value
end

local function lookup_count(key, counts)
  local normalized_key = normalize_count_key(key)
  return counts[normalized_key] or 0
end

local function render_badge(key, counts)
  local count = lookup_count(key, counts)
  local noun = count == 1 and "article" or "articles"

  return string.format(
    '<span class="homepage-count-badge" aria-hidden="true">%d</span><span class="visually-hidden">, %d %s</span>',
    count,
    count,
    noun
  )
end

local function render_badge_inlines(key, counts)
  local count = lookup_count(key, counts)
  local noun = count == 1 and "article" or "articles"

  local badge = pandoc.Span(
    { pandoc.Str(tostring(count)) },
    pandoc.Attr("", { "homepage-count-badge" }, { { "aria-hidden", "true" } })
  )

  local accessible = pandoc.Span(
    {
      pandoc.Str(","),
      pandoc.Space(),
      pandoc.Str(tostring(count)),
      pandoc.Space(),
      pandoc.Str(noun),
    },
    pandoc.Attr("", { "visually-hidden" })
  )

  return { badge, accessible }
end

local function replace_count_markers(text, counts)
  if not text or text == "" then
    return text
  end

  text = text:gsub(
    '<span%s+data%-article%-count%s*=%s*"([^"]+)"%s*></span>',
    function(key)
      return render_badge(key, counts)
    end
  )

  text = text:gsub(
    "<span%s+data%-article%-count%s*=%s*'([^']+)'%s*></span>",
    function(key)
      return render_badge(key, counts)
    end
  )

  return text
end

local function is_project_homepage(project_root)
  local input_file = get_input_file()
  if not input_file then
    return false
  end

  local current_path = resolve_path(project_root, input_file)
  local homepage_path = join_fs(project_root, "index.qmd")
  return path_key(current_path) == path_key(homepage_path)
end

function Pandoc(document)
  if not FORMAT:match("html") then
    return document
  end

  local project_root = get_project_root()
  if not is_project_homepage(project_root) then
    return document
  end

  local counts = build_counts(project_root)

  return document:walk({
    Span = function(element)
      local key = element.attributes and element.attributes["data-article-count"]
      if key and key ~= "" then
        return render_badge_inlines(key, counts)
      end
      return element
    end,
    RawBlock = function(element)
      if element.format == "html" then
        element.text = replace_count_markers(element.text, counts)
      end
      return element
    end,
    RawInline = function(element)
      if element.format == "html" then
        element.text = replace_count_markers(element.text, counts)
      end
      return element
    end,
  })
end
