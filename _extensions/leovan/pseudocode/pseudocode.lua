local function ensure_html_deps()
  quarto.doc.include_file("in-header", "in_header.html")
  quarto.doc.include_file("after-body", "after_body.html")
end

local function ensure_latex_deps()
  quarto.doc.use_latex_package("algorithm")
  quarto.doc.use_latex_package("algpseudocode")
end

local function extract_source_code_options(source_code, render_type)
  local options = {}
  local source_codes = {}
  local found_source_code = false

  for str in string.gmatch(source_code, "([^\n]*)\n?") do
    if (string.match(str, "^%s*#|.*") or string.gsub(str, "%s", "") == "") and not found_source_code then
      if string.match(str, "^%s*#|%s+[" .. render_type .. "|label].*") then
        str = string.gsub(str, "^%s*#|%s+", "")
        local idx_start, idx_end = string.find(str, ":%s*")

        if idx_start and idx_end and idx_end + 1 < #str then
          k = string.sub(str, 1, idx_start - 1)
          v = string.sub(str, idx_end + 1)
          v = string.gsub(v, "^\"%s*", "")
          v = string.gsub(v, "%s*\"$", "")

          options[k] = v
        else
          quarto.log.warning("Invalid pseducode option: " .. str)
        end
      end
    else
      found_source_code = true
      table.insert(source_codes, str)
    end
  end

  return options, table.concat(source_codes, "\n")
end

local function render_pseudocode_block_html(global_options)
  ensure_html_deps()

  local filter = {
    CodeBlock = function(el)
      if not el.attr.classes:includes("pseudocode") then
        return el
      end

      local options, source_code = extract_source_code_options(el.text, "html")

      source_code = string.gsub(source_code, "%s*\\begin{algorithm}[^\n]+", "\\begin{algorithm}")
      source_code = string.gsub(source_code, "%s*\\begin{algorithmic}[^\n]+", "\\begin{algorithmic}")

      local alg_id = options["label"]
      options["label"] = nil
      options["html-alg-title"] = global_options.alg_title
      options["html-pseudocode-index"] = global_options.html_current_index
      global_options.html_current_index = global_options.html_current_index + 1

      if global_options.chapter_level then
        options["html-chapter-level"] = global_options.chapter_level
      end

      local data_options = {}
      for k, v in pairs(options) do
        if string.match(k, "^html-") then
          data_k = string.gsub(k, "^html", "data")
          data_options[data_k] = v
        end
      end

      local inner_el = pandoc.Div(source_code)
      inner_el.attr.classes = pandoc.List()
      inner_el.attr.classes:insert("pseudocode")

      local outer_el = pandoc.Div(inner_el)
      outer_el.attr.classes = pandoc.List()
      outer_el.attr.classes:insert("pseudocode-container")
      outer_el.attr.attributes = data_options

      if alg_id then
        outer_el.attr.identifier = alg_id
      end

      return outer_el
    end
  }

  return filter
end

local function render_pseudocode_block_latex(global_options)
  ensure_latex_deps()
  quarto.doc.include_text("before-body", "\\floatname{algorithm}{" .. global_options.alg_title .. "}")

  local filter = {
    CodeBlock = function(el)
      if not el.attr.classes:includes("pseudocode") then
        return el
      end

      local options, source_code = extract_source_code_options(el.text, "pdf")

      if options["pdf-placement"] then
        source_code = string.gsub(source_code, "\\begin{algorithm}%s*\n", "\\begin{algorithm}[" .. options["pdf-placement"] .. "]\n")
      end

      if not options["pdf-line-number"] or options["pdf-line-number"] == "true" then
        source_code = string.gsub(source_code, "\\begin{algorithmic}%s*\n", "\\begin{algorithmic}[1]\n")
      end

      if options["label"] then
        source_code = string.gsub(source_code, "\\begin{algorithmic}", "\\label{" .. options["label"] .. "}\n\\begin{algorithmic}")
      end

      return pandoc.RawInline("latex", source_code)
    end
  }

  return filter
end

local function render_pseudocode_block(global_options)
  local filter = {
    CodeBlock = function(el)
      return el
    end
  }

  if quarto.doc.is_format("html") then
    filter = render_pseudocode_block_html(global_options)
  elseif quarto.doc.is_format("latex") then
    filter = render_pseudocode_block_latex(global_options)
  end

  return filter
end

local function render_pseudocode_ref_html(global_options)
  local filter = {
    Cite = function(el)
      local cite_text = pandoc.utils.stringify(el.content)

      for k, v in pairs(global_options.html_identifier_index_mapping) do
        if cite_text == "@" .. k then
          local link_src = "#" .. k
          local alg_id = v

          if global_options.chapater_level then
            alg_id = global_options.chapater_level .. "." .. alg_id
          end

          local link_text = global_options.alg_prefix .. " " .. alg_id
          return pandoc.Link(link_text, link_src)
        end
      end
    end
  }

  return filter
end

local function render_pseudocode_ref_latex(global_options)
  local filter = {
    Cite = function(el)
      local cite_text = pandoc.utils.stringify(el.content)

      if string.match(cite_text, "^@alg-") then
        return pandoc.RawInline("latex", " " .. global_options.alg_prefix .. "~\\ref{" .. string.gsub(cite_text, "^@", "") .. "} " )
      end
    end
  }

  return filter
end

local function render_pseudocode_ref(global_options)
  local filter = {
    Cite = function(el)
      return el
    end
  }

  if quarto.doc.is_format("html") then
    filter = render_pseudocode_ref_html(global_options)
  elseif quarto.doc.is_format("latex") then
    filter = render_pseudocode_ref_latex(global_options)
  end

  return filter
end

function Pandoc(doc)
  local global_options = {
    alg_title = "Algorithm",
    alg_prefix = "Algorithm",
    chapater_level = nil,
    html_current_index = 1,
    html_identifier_index_mapping = {}
  }

  if doc.meta["pseudocode"] then
    global_options.alg_title = pandoc.utils.stringify(doc.meta["pseudocode"]["alg-title"]) or "Algorithm"
    global_options.alg_prefix = pandoc.utils.stringify(doc.meta["pseudocode"]["alg-prefix"]) or "Algorithm"
  end

  if doc.meta["book"] then
    local _, input_qmd_filename = string.match(quarto.doc["input_file"], "^(.-)([^\\/]-%.([^\\/%.]-))$")
    local renders = doc.meta["book"]["render"]

    for _, render in pairs(renders) do
      if render["file"] and render["number"] and pandoc.utils.stringify(render["file"]) == input_qmd_filename then
        global_options.chapater_level = pandoc.utils.stringify(render["number"])
      end
    end
  end

  doc = doc:walk(render_pseudocode_block(global_options))

  for _, el in pairs(doc.blocks) do
    if el.t == "Div" and el.attr and el.attr.classes:includes("pseudocode-container") then
      global_options.html_identifier_index_mapping[el.identifier] = el.attr.attributes["data-pseudocode-index"]
    end
  end

  return doc:walk(render_pseudocode_ref(global_options))
end
