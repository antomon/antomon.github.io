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
    min-height: 360px;
    }

    .quarto-title-block .quarto-title-banner::after {
    content: "";
    position: absolute;
    top: 0;
    right: 0;
    width: 34%;
    height: 280px;
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    border-bottom-left-radius: 18px;
    z-index: 1;
    }

    .quarto-title-block .quarto-title-banner::before {
    content: "";
    position: absolute;
    top: 0;
    right: 28%;
    width: 14%;
    height: 280px;
    background: linear-gradient(
        to right,
        rgba(93,53,156,1) 0%,
        rgba(93,53,156,0.92) 35%,
        rgba(93,53,156,0.45) 70%,
        rgba(93,53,156,0) 100%
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
    max-width: 62%;
    padding-right: 1rem;
    }

    .quarto-title-block .description {
    display: none;
    }

    @media (max-width: 991px) {
    .quarto-title-block .quarto-title-banner {
        min-height: auto;
    }

    .quarto-title-block .quarto-title-banner::after {
        width: 30%;
        height: 220px;
        opacity: 0.55;
    }

    .quarto-title-block .quarto-title-banner::before {
        right: 24%;
        width: 14%;
        height: 220px;
    }

    .quarto-title-block .quarto-title {
        max-width: 75%;
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

  local script = '<script>document.addEventListener("DOMContentLoaded",function(){var b=document.querySelector(".quarto-title-block .quarto-title-banner");if(b){b.style.setProperty("--banner-image","url(\'' .. image .. '\')");var st=document.createElement("style");st.textContent=".quarto-title-block .quarto-title-banner::after{background-image:var(--banner-image);}";document.head.appendChild(st);}});</script>'

  table.insert(doc.blocks, 1, pandoc.RawBlock("html", css))
  table.insert(doc.blocks, 2, pandoc.RawBlock("html", script))

  return doc
end