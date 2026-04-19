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
  min-height: 340px;
  background: #6437a0;
}

.quarto-title-block .quarto-title-banner::after {
  content: "";
  position: absolute;
  top: 50%;
  right: 3%;
  transform: translateY(-50%);
  width: 34%;
  height: 270px;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  z-index: 1;
  box-shadow: 0 10px 30px rgba(0,0,0,0.18);
}

.quarto-title-block .quarto-title-banner::before {
  content: "";
  position: absolute;
  top: 50%;
  right: 32%;
  transform: translateY(-50%);
  width: 14%;
  height: 270px;
  background: linear-gradient(
    to right,
    rgba(100,55,160,1) 0%,
    rgba(100,55,160,0.92) 30%,
    rgba(100,55,160,0.45) 72%,
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
  max-width: 55%;
  padding-right: 0.75rem;
}

.quarto-title-block .description {
  display: none;
}

/* full width strip under title block */
.banner-info-strip-outer {
  width: 100vw;
  margin-left: calc(50% - 50vw);
  margin-right: calc(50% - 50vw);
  background: #ffffff;
  box-sizing: border-box;
}

.banner-info-strip-inner {
  width: 100%;
  box-sizing: border-box;
  padding: 1.5rem 2rem 0.75rem 2rem;
}

.banner-info-strip-inner .quarto-title-meta {
  width: 100% !important;
  max-width: none !important;
  margin: 0 0 1rem 0 !important;
}

.banner-info-strip-inner .article-standfirst {
  width: 100%;
  max-width: none;
  box-sizing: border-box;
  font-size: 1.08rem;
  line-height: 1.75;
  margin: 0 0 1.5rem 0;
  padding: 1.1rem 1.25rem;
  border-left: 4px solid rgba(100,55,160,0.45);
  background: rgba(100,55,160,0.06);
  color: #5f6368;
}

.banner-info-strip-inner .article-standfirst p {
  margin: 0;
}

@media (max-width: 991px) {
  .quarto-title-block .quarto-title-banner {
    min-height: 300px;
  }

  .quarto-title-block .quarto-title-banner::after {
    width: 34%;
    height: 220px;
    right: 2%;
    opacity: 0.7;
  }

  .quarto-title-block .quarto-title-banner::before {
    right: 30%;
    width: 16%;
    height: 220px;
  }

  .quarto-title-block .quarto-title {
    max-width: 62%;
    padding-right: 0.5rem;
  }

  .banner-info-strip-inner {
    padding: 1.25rem 1.5rem 0.5rem 1.5rem;
  }

  .banner-info-strip-inner .article-standfirst {
    padding: 1rem;
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

  .banner-info-strip-inner {
    padding: 1rem 1rem 0.5rem 1rem;
  }

  .banner-info-strip-inner .article-standfirst {
    padding: 0.9rem 1rem;
    margin-bottom: 1.25rem;
  }
}
</style>
]]

  local image_style =
    '<style>.quarto-title-block .quarto-title-banner::after{background-image:url("' .. image .. '");}</style>'

  local script = [[
<script>
document.addEventListener("DOMContentLoaded", function () {
  var titleBlock = document.querySelector(".quarto-title-block");
  if (!titleBlock) return;

  var metaBlocks = titleBlock.querySelectorAll(".quarto-title-meta");
  if (!metaBlocks || metaBlocks.length === 0) return;

  var standfirst = document.querySelector(".article-standfirst");

  var outer = document.createElement("div");
  outer.className = "banner-info-strip-outer";

  var inner = document.createElement("div");
  inner.className = "banner-info-strip-inner";

  metaBlocks.forEach(function(meta) {
    inner.appendChild(meta);
  });

  if (standfirst) {
    inner.appendChild(standfirst);
  }

  outer.appendChild(inner);
  titleBlock.insertAdjacentElement("afterend", outer);
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