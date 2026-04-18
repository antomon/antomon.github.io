local function stringify_meta(x)
  if not x then
    return nil
  end
  return pandoc.utils.stringify(x)
end

function Pandoc(doc)
  local image = stringify_meta(doc.meta.image)
  if not image or image == "" then
    return doc
  end

  local css = [[
<style>
.quarto-title-block .quarto-title-banner {
  position: relative;
  overflow: hidden;
}

.quarto-title-block .quarto-title-banner::after {
  content: "";
  position: absolute;
  top: 0;
  right: 0;
  width: 38%;
  height: 100%;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  z-index: 1;
}

.quarto-title-block .quarto-title-banner::before {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to right,
    rgba(93,53,156,1) 0%,
    rgba(93,53,156,1) 55%,
    rgba(93,53,156,0.78) 68%,
    rgba(93,53,156,0.18) 80%,
    rgba(93,53,156,0) 100%
  );
  z-index: 2;
  pointer-events: none;
}

.quarto-title-block .quarto-title,
.quarto-title-block .quarto-title-meta,
.quarto-title-block .description,
.quarto-title-block .quarto-categories,
.quarto-title-block .subtitle,
.quarto-title-block .title {
  position: relative;
  z-index: 3;
}

.quarto-title-block .quarto-title {
  max-width: 60%;
}

@media (max-width: 991px) {
  .quarto-title-block .quarto-title-banner::after {
    width: 32%;
    opacity: 0.45;
  }

  .quarto-title-block .quarto-title {
    max-width: 100%;
  }
}

@media (max-width: 575px) {
  .quarto-title-block .quarto-title-banner::after,
  .quarto-title-block .quarto-title-banner::before {
    display: none;
  }

  .quarto-title-block .quarto-title {
    max-width: 100%;
  }
}
</style>
]]

  local script = '<script>document.addEventListener("DOMContentLoaded",function(){var b=document.querySelector(".quarto-title-block .quarto-title-banner");if(b){b.style.setProperty("--banner-image","url(\'' .. image .. '\')");var st=document.createElement("style");st.textContent=".quarto-title-block .quarto-title-banner::after{background-image:var(--banner-image);}";document.head.appendChild(st);}});</script>'

  table.insert(doc.blocks, 1, pandoc.RawBlock("html", css))
  table.insert(doc.blocks, 2, pandoc.RawBlock("html", script))

  return doc
end