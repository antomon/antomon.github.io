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

.banner-meta-row {
  width: 100%;
  display: grid;
  gap: 0.35rem 2rem;
}

.banner-meta-row.row-1,
.banner-meta-row.row-2 {
  grid-template-columns: repeat(3, minmax(180px, 1fr));
}

.banner-meta-row.row-3 {
  grid-template-columns: 1fr;
}

/* explicit vertical rhythm */
.banner-meta-row.row-1 {
  margin: 0 0 1.5rem 0;
}

.banner-meta-row.row-2 {
  margin: 0 0 1.5rem 0;
}

.banner-meta-row.row-3 {
  margin: 0 0 1.5rem 0;
}

.banner-meta-row .quarto-title-meta,
.banner-meta-row .keywords {
  width: 100% !important;
  max-width: none !important;
  margin: 0 !important;
}

.banner-meta-row .quarto-title-meta > div {
  min-width: 0;
}

.banner-info-strip-inner .quarto-title-meta-heading,
.banner-info-strip-inner .block-title {
  font-size: 0.88rem !important;
  line-height: 1.2 !important;
  font-weight: 500 !important;
  letter-spacing: 0 !important;
  text-transform: uppercase !important;
  color: #6b7280 !important;
  margin: 0 0 0.35rem 0 !important;
  font-family: inherit !important;
}

.banner-info-strip-inner .quarto-title-meta-contents,
.banner-info-strip-inner .quarto-title-meta-contents *,
.banner-info-strip-inner .keywords p {
  font-size: 1rem !important;
  line-height: 1.45 !important;
  font-weight: 400 !important;
  color: #374151 !important;
  font-family: inherit !important;
  margin-top: 0 !important;
  margin-bottom: 0 !important;
}

.banner-info-strip-inner .article-standfirst {
  width: 100%;
  max-width: none;
  box-sizing: border-box;
  font-size: 1.08rem;
  line-height: 1.75;
  margin: 0.25rem 0 1.5rem 0;
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

  .banner-meta-row.row-1,
  .banner-meta-row.row-2 {
    grid-template-columns: repeat(2, minmax(180px, 1fr));
  }

  .banner-meta-row.row-1 {
    margin-bottom: 1.35rem;
  }

  .banner-meta-row.row-2 {
    margin-bottom: 1.35rem;
  }

  .banner-meta-row.row-3 {
    margin-bottom: 1.35rem;
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

  .banner-meta-row.row-1,
  .banner-meta-row.row-2 {
    grid-template-columns: 1fr;
    gap: 0.75rem 0;
  }

  .banner-meta-row.row-1 {
    margin-bottom: 1.25rem;
  }

  .banner-meta-row.row-2 {
    margin-bottom: 1.25rem;
  }

  .banner-meta-row.row-3 {
    margin-bottom: 1.25rem;
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

  var authorBlock = titleBlock.querySelector(".quarto-title-meta-author");
  var metaBlock = titleBlock.querySelector(".quarto-title-meta");
  var keywordsBlock = titleBlock.querySelector(".keywords");
  var standfirst = document.querySelector(".article-standfirst");

  function makeMetaBlock(labelText, valueNode) {
    if (!labelText || !valueNode) return null;

    var wrapper = document.createElement("div");
    wrapper.className = "quarto-title-meta";

    var item = document.createElement("div");

    var heading = document.createElement("div");
    heading.className = "quarto-title-meta-heading";
    heading.textContent = labelText;

    var contents = document.createElement("div");
    contents.className = "quarto-title-meta-contents";
    contents.appendChild(valueNode.cloneNode(true));

    item.appendChild(heading);
    item.appendChild(contents);
    wrapper.appendChild(item);

    return wrapper;
  }

  function normalizeAuthorBlock(block) {
    if (!block) return [];

    var children = Array.from(block.children);
    if (children.length < 4) return [];

    var authorHeading = children[0] ? children[0].textContent.trim() : "Author";
    var affiliationHeading = children[1] ? children[1].textContent.trim() : "Affiliation";
    var authorValue = children[2];
    var affiliationValue = children[3];

    var out = [];
    var authorMeta = makeMetaBlock(authorHeading, authorValue);
    var affiliationMeta = makeMetaBlock(affiliationHeading, affiliationValue);

    if (authorMeta) out.push(authorMeta);

    var affiliationText = affiliationValue ? affiliationValue.textContent.replace(/\s+/g, " ").trim() : "";
    if (affiliationMeta && affiliationText !== "") out.push(affiliationMeta);

    return out;
  }

  function normalizePublishedModified(block) {
    if (!block) return [];

    var items = Array.from(block.children);
    if (!items.length) return [];

    var out = [];

    items.forEach(function(item) {
      var heading = item.querySelector(".quarto-title-meta-heading");
      var contents = item.querySelector(".quarto-title-meta-contents");
      if (!heading || !contents) return;

      var valueNode;
      if (contents.children.length === 1) {
        valueNode = contents.children[0];
      } else {
        valueNode = document.createElement("div");
        Array.from(contents.childNodes).forEach(function(node) {
          valueNode.appendChild(node.cloneNode(true));
        });
      }

      var text = valueNode.textContent.replace(/\s+/g, " ").trim();
      if (text === "") return;

      var meta = makeMetaBlock(heading.textContent.trim(), valueNode);
      if (meta) out.push(meta);
    });

    return out;
  }

  function buildReadingTimeBlock() {
    var content = document.querySelector("#quarto-document-content");
    if (!content) return null;

    var text = content.innerText || "";
    text = text.replace(/\s+/g, " ").trim();
    if (!text) return null;

    var words = text.split(" ").length;
    var minutes = Math.max(1, Math.round(words / 200));

    var p = document.createElement("p");
    p.textContent = minutes + " min";

    return makeMetaBlock("Reading time", p);
  }

  var hasSomething = authorBlock || metaBlock || keywordsBlock || standfirst;
  if (!hasSomething) return;

  var outer = document.createElement("div");
  outer.className = "banner-info-strip-outer";

  var inner = document.createElement("div");
  inner.className = "banner-info-strip-inner";

  var row1 = document.createElement("div");
  row1.className = "banner-meta-row row-1";

  var row2 = document.createElement("div");
  row2.className = "banner-meta-row row-2";

  var row3 = document.createElement("div");
  row3.className = "banner-meta-row row-3";

  normalizeAuthorBlock(authorBlock).forEach(function(block) {
    row1.appendChild(block);
  });

  normalizePublishedModified(metaBlock).forEach(function(block) {
    row2.appendChild(block);
  });

  var readingTimeBlock = buildReadingTimeBlock();
  if (readingTimeBlock) row2.appendChild(readingTimeBlock);

  if (keywordsBlock) {
    var kwText = keywordsBlock.textContent.replace(/\s+/g, " ").trim();
    if (kwText !== "") {
      row3.appendChild(keywordsBlock.cloneNode(true));
    }
  }

  if (row1.children.length) inner.appendChild(row1);
  if (row2.children.length) inner.appendChild(row2);
  if (row3.children.length) inner.appendChild(row3);
  if (standfirst) inner.appendChild(standfirst);

  if (authorBlock) authorBlock.remove();
  if (metaBlock) metaBlock.remove();
  if (keywordsBlock) keywordsBlock.remove();

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