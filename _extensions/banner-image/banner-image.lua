local function stringify_meta(x)
  if not x then
    return nil
  end
  return pandoc.utils.stringify(x)
end

function Pandoc(doc)
  local function stringify_meta(x)
    if not x then
      return nil
    end
    return pandoc.utils.stringify(x)
  end

  local image = stringify_meta(doc.meta.image)
  if not image or image == "" then
    return doc
  end

  local description = stringify_meta(doc.meta.description)

  local css = [[
<style>
.quarto-title-block .quarto-title-banner {
  position: relative;
  overflow: hidden;
  min-height: 320px;
  background: #6437a0;
}

.quarto-title-block .quarto-title-banner::after {
  content: "";
  position: absolute;
  top: 0;
  right: 0;
  width: 36%;
  height: 260px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  z-index: 1;
}

.quarto-title-block .quarto-title-banner::before {
  content: "";
  position: absolute;
  top: 0;
  right: 36%;
  width: 10%;
  height: 260px;
  background: linear-gradient(
    to right,
    rgba(100,55,160,1) 0%,
    rgba(100,55,160,0.88) 35%,
    rgba(100,55,160,0.42) 70%,
    rgba(100,55,160,0) 100%
  );
  z-index: 2;
  pointer-events: none;
}

.quarto-title-block .quarto-title,
.quarto-title-block .quarto-title-meta,
.quarto-title-block .quarto-categories,
.quarto-title-block .subtitle,
.quarto-title-block .title {
  position: relative;
  z-index: 3;
}

.quarto-title-block .quarto-title {
  max-width: 58%;
  padding-right: 1rem;
}

.quarto-title-block .description {
  display: none;
}

.article-standfirst {
  font-size: 1.05rem;
  line-height: 1.6;
  margin: 1.25rem 0 2rem 0;
  color: var(--bs-secondary-color, #6c757d);
}

@media (max-width: 991px) {
  .quarto-title-block .quarto-title-banner {
    min-height: 280px;
  }

  .quarto-title-block .quarto-title-banner::after {
    width: 32%;
    height: 220px;
    opacity: 0.55;
  }

  .quarto-title-block .quarto-title-banner::before {
    right: 32%;
    width: 12%;
    height: 220px;
  }

  .quarto-title-block .quarto-title {
    max-width: 72%;
  }
}

@media (max-width: 575px) {
  .quarto-title-block .quarto-title-banner::after,
  .quarto-title-block .quarto-title-banner::before {
    display: none;
  }

  .quarto-title-block .quarto-title {
    max-width: 100%;
    padding-right: 0;
  }
}
</style>
]]

  local image_style = '<style>.quarto-title-block .quarto-title-banner::after{background-image:url("' .. image .. '");}</style>'

  local script = [[
<script>
document.addEventListener("DOMContentLoaded", function () {
  var standfirst = document.querySelector(".article-standfirst");
  var keywords = document.querySelector(".keywords");
  if (standfirst && keywords && keywords.parentNode) {
    keywords.parentNode.insertAdjacentElement("afterend", standfirst);
  }
});
</script>
]]

  table.insert(doc.blocks, 1, pandoc.RawBlock("html", css))
  table.insert(doc.blocks, 2, pandoc.RawBlock("html", image_style))
  table.insert(doc.blocks, 3, pandoc.RawBlock("html", script))

  if description and description ~= "" then
    local standfirst = pandoc.Div(
      { pandoc.Para({ pandoc.Str(description) }) },
      pandoc.Attr("", { "article-standfirst" })
    )

    local inserted = false
    for i, block in ipairs(doc.blocks) do
      if block.t == "Header" then
        table.insert(doc.blocks, i, standfirst)
        inserted = true
        break
      end
    end

    if not inserted then
      table.insert(doc.blocks, 4, standfirst)
    end
  end

  return doc
end