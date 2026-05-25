vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.bo.formatprg = "mdsf format --stdin --log-level=off"

local function show_toc_side()
    local current_win = vim.api.nvim_get_current_win()

    require("vim.treesitter._headings").show_toc()

    if
        vim.api.nvim_get_current_win() == current_win
        or vim.bo.filetype ~= "qf"
    then
        return
    end

    vim.cmd.wincmd "H"
    vim.cmd "vertical resize 42"
end

local function add_range(ranges, start_col, end_col)
    if start_col > end_col then
        return
    end

    ranges[#ranges + 1] = { start_col, end_col }
end

local function split_trailing_punctuation(token)
    local bare_token = token:gsub("[.,;:!?]+$", "")
    return bare_token, token:sub(#bare_token + 1)
end

local function format_bare_link(token)
    if token:match "^https?://" then
        return "<" .. token .. ">"
    end

    return "[" .. token .. "](" .. token .. ")"
end

local function wrap_bare_links_in_text(text)
    local chunks = {}
    local replacements = 0
    local idx = 1

    while idx <= #text do
        local start_col, end_col =
            text:find("https?://[%w%._~:/%?#%[%]@!$&'()*+,;=%-]+", idx)
        local match_type = "url"

        local function consider_path(pattern)
            local path_start, path_end = text:find(pattern, idx)
            if path_start and (not start_col or path_start < start_col) then
                start_col = path_start
                end_col = path_end
                match_type = "path"
            end
        end

        consider_path "%./[%w%._%-%+/]+"
        consider_path "%.%./[%w%._%-%+/]+"
        consider_path "/[%w%._%-%+/]+"

        if not start_col then
            chunks[#chunks + 1] = text:sub(idx)
            break
        end

        chunks[#chunks + 1] = text:sub(idx, start_col - 1)

        local token = text:sub(start_col, end_col)
        local bare_token, trailing_punctuation =
            split_trailing_punctuation(token)

        if bare_token == "" then
            chunks[#chunks + 1] = token
        else
            local previous_char = start_col > 1
                    and text:sub(start_col - 1, start_col - 1)
                or ""
            if
                match_type == "path"
                and previous_char ~= ""
                and previous_char:match "[%w%]%)]"
            then
                chunks[#chunks + 1] = token
            else
                replacements = replacements + 1
                chunks[#chunks + 1] = format_bare_link(bare_token)
                    .. trailing_punctuation
            end
        end

        idx = end_col + 1
    end

    return table.concat(chunks), replacements
end

local function merge_ranges(ranges)
    table.sort(ranges, function(left, right)
        return left[1] < right[1]
    end)

    local merged_ranges = {}
    for _, range in ipairs(ranges) do
        local previous_range = merged_ranges[#merged_ranges]
        if not previous_range or range[1] > previous_range[2] + 1 then
            merged_ranges[#merged_ranges + 1] = range
        else
            previous_range[2] = math.max(previous_range[2], range[2])
        end
    end

    return merged_ranges
end

local function wrap_bare_links_in_line(line, protected_ranges)
    local chunks = {}
    local replacements = 0
    local next_col = 1

    for _, range in ipairs(protected_ranges) do
        if next_col < range[1] then
            local wrapped_chunk, chunk_replacements =
                wrap_bare_links_in_text(line:sub(next_col, range[1] - 1))
            chunks[#chunks + 1] = wrapped_chunk
            replacements = replacements + chunk_replacements
        end

        chunks[#chunks + 1] = line:sub(range[1], range[2])
        next_col = range[2] + 1
    end

    if next_col <= #line then
        local wrapped_chunk, chunk_replacements =
            wrap_bare_links_in_text(line:sub(next_col))
        chunks[#chunks + 1] = wrapped_chunk
        replacements = replacements + chunk_replacements
    end

    return table.concat(chunks), replacements
end

local function collect_scanner_line_ranges(line)
    local ranges = {}
    local idx = 1

    while idx <= #line do
        local start_tick, end_tick = line:find("`+", idx)
        if not start_tick then
            break
        end

        local fence = line:sub(start_tick, end_tick)
        local close_tick_start, close_tick_end =
            line:find(fence, end_tick + 1, true)
        if not close_tick_start then
            break
        end

        add_range(ranges, start_tick, close_tick_end)
        idx = close_tick_end + 1
    end

    idx = 1
    while idx <= #line do
        local http_start, http_end = line:find("<http://[^%s>]+>", idx)
        local https_start, https_end = line:find("<https://[^%s>]+>", idx)
        local start_col = http_start
        local end_col = http_end

        if https_start and (not start_col or https_start < start_col) then
            start_col = https_start
            end_col = https_end
        end

        if not start_col then
            break
        end

        add_range(ranges, start_col, end_col)
        idx = end_col + 1
    end

    idx = 1
    while idx <= #line do
        local link_start, link_end = line:find("%b[]%b()", idx)
        if not link_start then
            break
        end

        add_range(ranges, link_start, link_end)
        idx = link_end + 1
    end

    return merge_ranges(ranges)
end

local function update_fence_state(line, fence_state)
    local indent, marker = line:match "^(%s*)([`~]+)"
    if not marker or #marker < 3 then
        return fence_state
    end

    if fence_state and marker:sub(1, 1) == fence_state.marker then
        if #marker >= fence_state.length and #indent <= 3 then
            return nil
        end

        return fence_state
    end

    if fence_state then
        return fence_state
    end

    return {
        marker = marker:sub(1, 1),
        length = #marker,
    }
end

local function collect_scanner_protected_ranges(lines)
    local ranges_by_line = {}
    local fence_state = nil

    for idx, line in ipairs(lines) do
        if fence_state then
            ranges_by_line[idx] = { { 1, math.max(#line, 1) } }
            fence_state = update_fence_state(line, fence_state)
        else
            local next_fence_state = update_fence_state(line, fence_state)
            if next_fence_state then
                ranges_by_line[idx] = { { 1, math.max(#line, 1) } }
                fence_state = next_fence_state
            else
                ranges_by_line[idx] = collect_scanner_line_ranges(line)
            end
        end
    end

    return ranges_by_line
end

local function add_node_ranges_by_line(ranges_by_line, node)
    local start_row, start_col, end_row, end_col = node:range()

    for line_idx = start_row, end_row do
        local line_ranges = ranges_by_line[line_idx + 1]
        if not line_ranges then
            line_ranges = {}
            ranges_by_line[line_idx + 1] = line_ranges
        end

        local range_start_col = line_idx == start_row and start_col + 1 or 1
        local range_end_col = line_idx == end_row and end_col or math.huge
        add_range(line_ranges, range_start_col, range_end_col)
    end
end

local function collect_parser_protected_ranges(bufnr, language, protected_types)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, language)
    if not ok then
        return nil
    end

    local parse_ok, trees = pcall(function()
        return parser:parse()
    end)
    if not parse_ok then
        return nil
    end

    local ranges_by_line = {}

    local function walk(node)
        if protected_types[node:type()] then
            add_node_ranges_by_line(ranges_by_line, node)
            return
        end

        for child in node:iter_children() do
            walk(child)
        end
    end

    for _, tree in ipairs(trees) do
        walk(tree:root())
    end

    return ranges_by_line
end

local function merge_ranges_by_line(...)
    local merged_by_line = {}

    for _, ranges_by_line in ipairs { ... } do
        if ranges_by_line then
            for line_idx, ranges in pairs(ranges_by_line) do
                local line_ranges = merged_by_line[line_idx]
                if not line_ranges then
                    line_ranges = {}
                    merged_by_line[line_idx] = line_ranges
                end

                for _, range in ipairs(ranges) do
                    line_ranges[#line_ranges + 1] = range
                end
            end
        end
    end

    for line_idx, ranges in pairs(merged_by_line) do
        merged_by_line[line_idx] = merge_ranges(ranges)
    end

    return merged_by_line
end

local function collect_treesitter_protected_ranges(bufnr)
    local markdown_ranges = collect_parser_protected_ranges(bufnr, "markdown", {
        fenced_code_block = true,
    })
    local inline_ranges =
        collect_parser_protected_ranges(bufnr, "markdown_inline", {
            code_span = true,
            inline_link = true,
            uri_autolink = true,
        })

    if not markdown_ranges or not inline_ranges then
        return nil
    end

    return merge_ranges_by_line(markdown_ranges, inline_ranges)
end

local function find_parent(node, type_name)
    while node do
        if node:type() == type_name then
            return node
        end

        node = node:parent()
    end
end

local function list_item_markers(list_item)
    local list_marker
    local task_marker

    for child in list_item:iter_children() do
        local type_name = child:type()
        if type_name == "list_marker_minus" then
            list_marker = child
        elseif
            type_name == "task_list_marker_unchecked"
            or type_name == "task_list_marker_checked"
        then
            task_marker = child
        end
    end

    return list_marker, task_marker
end

local function get_markdown_node_at_cursor(bufnr)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1

    local node = vim.treesitter.get_node {
        bufnr = bufnr,
        pos = { row, col },
        lang = "markdown",
    }

    if node or col == 0 then
        return node
    end

    return vim.treesitter.get_node {
        bufnr = bufnr,
        pos = { row, col - 1 },
        lang = "markdown",
    }
end

local function make_current_line_list_item(bufnr)
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local indent = line:match "^%s*" or ""

    vim.api.nvim_buf_set_text(bufnr, row, #indent, row, #indent, { "- " })
end

local function first_nonblank_col(line)
    local first_nonblank = line:find "%S"
    if not first_nonblank then
        return nil
    end

    return first_nonblank - 1
end

local function toggle_markdown_list_item()
    local bufnr = 0

    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
    if not ok then
        vim.notify(
            "No markdown Treesitter parser available",
            vim.log.levels.WARN
        )
        return
    end

    parser:parse()

    local list_item =
        find_parent(get_markdown_node_at_cursor(bufnr), "list_item")
    if not list_item then
        make_current_line_list_item(bufnr)
        return
    end

    local list_marker, task_marker = list_item_markers(list_item)
    if not list_marker then
        return
    end

    local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
    local list_marker_row = list_marker:range()
    if list_marker_row ~= cursor_row then
        make_current_line_list_item(bufnr)
        return
    end

    local task_type = task_marker and task_marker:type()
    if task_type == "task_list_marker_checked" then
        local sr, _, er, ec = task_marker:range()
        local line = vim.api.nvim_buf_get_lines(bufnr, sr, sr + 1, false)[1]
            or ""
        local marker_start_col = first_nonblank_col(line)
        if not marker_start_col then
            return
        end

        local trailing_space = line:sub(ec + 1):match "^%s*" or ""
        vim.api.nvim_buf_set_text(
            bufnr,
            sr,
            marker_start_col,
            er,
            ec + #trailing_space,
            { "" }
        )
        return
    end

    if task_type == "task_list_marker_unchecked" then
        local sr, sc, er, ec = task_marker:range()
        vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, { "[x]" })
        return
    end

    local sr, _, er, ec = list_marker:range()
    local line = vim.api.nvim_buf_get_lines(bufnr, sr, sr + 1, false)[1] or ""
    local marker_start_col = first_nonblank_col(line)
    if not marker_start_col then
        return
    end

    vim.api.nvim_buf_set_text(bufnr, sr, marker_start_col, er, ec, { "- [ ] " })
end

local function wrap_bare_links_in_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local updated_lines = vim.deepcopy(lines)
    local protected_ranges_by_line = collect_treesitter_protected_ranges(bufnr)
        or collect_scanner_protected_ranges(lines)
    local replacements = 0

    for idx, line in ipairs(lines) do
        local updated_line, line_replacements =
            wrap_bare_links_in_line(line, protected_ranges_by_line[idx] or {})
        updated_lines[idx] = updated_line
        replacements = replacements + line_replacements
    end

    if replacements == 0 then
        vim.notify("No bare links found", vim.log.levels.INFO)
        return
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, updated_lines)
    vim.notify(
        "Wrapped "
            .. replacements
            .. " bare link"
            .. (replacements == 1 and "" or "s"),
        vim.log.levels.INFO
    )
end

local function markdown_buffer_text(bufnr)
    return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
        .. "\n"
end

local function markdown_pdf_output_path(path)
    return path .. ".pdf"
end

local function preprocess_markdown_pdf_content(content, context)
    local hook = vim.g.markdown_pdf_preprocess
    if hook == nil then
        return content
    end

    if type(hook) ~= "function" then
        vim.notify(
            "vim.g.markdown_pdf_preprocess must be a function",
            vim.log.levels.ERROR
        )
        return nil
    end

    local ok, preprocessed_content = pcall(hook, content, context)
    if not ok then
        vim.notify(
            "Markdown PDF preprocess hook failed: "
                .. tostring(preprocessed_content),
            vim.log.levels.ERROR
        )
        return nil
    end

    if type(preprocessed_content) ~= "string" then
        vim.notify(
            "Markdown PDF preprocess hook must return a string",
            vim.log.levels.ERROR
        )
        return nil
    end

    return preprocessed_content
end

local function generate_markdown_pdf()
    local bufnr = vim.api.nvim_get_current_buf()
    local input_path = vim.api.nvim_buf_get_name(bufnr)

    if input_path == "" then
        vim.notify(
            "Cannot generate PDF for a Markdown buffer without a file path",
            vim.log.levels.WARN
        )
        return
    end

    if vim.fn.executable "pandoc" == 0 then
        vim.notify(
            "pandoc is required to generate Markdown PDFs",
            vim.log.levels.ERROR
        )
        return
    end

    if vim.fn.executable "typst" == 0 then
        vim.notify(
            "typst is required to render Markdown PDFs",
            vim.log.levels.ERROR
        )
        return
    end

    local output_path = markdown_pdf_output_path(input_path)
    local cwd = vim.fs.dirname(input_path)
    local content =
        preprocess_markdown_pdf_content(markdown_buffer_text(bufnr), {
            bufnr = bufnr,
            input_path = input_path,
            output_path = output_path,
            cwd = cwd,
        })
    if not content then
        return
    end

    local result = vim.system({
        "pandoc",
        "--from=gfm",
        "--to=pdf",
        "--standalone",
        "--pdf-engine=typst",
        "--toc",
        "--toc-depth=3",
        "--resource-path=.",
        "--output",
        output_path,
        "-",
    }, {
        cwd = cwd,
        stdin = content,
        text = true,
    }):wait()

    if result.code == 0 then
        vim.notify("Generated " .. output_path, vim.log.levels.INFO)
        return
    end

    local details =
        vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
    if details == "" then
        details = "pandoc exited with code " .. result.code
    end

    vim.notify(
        "Failed to generate Markdown PDF: " .. details,
        vim.log.levels.ERROR
    )
end

local function setup_formatters()
    vim.keymap.set("v", "<localleader>fi", function()
        return "c*<C-r>-*<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with italic markers (*)",
    })
    vim.keymap.set("v", "<localleader>fb", function()
        return "c**<C-r>-**<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with bold markers (**)",
    })
    vim.keymap.set("v", "<localleader>fc", function()
        return "c`<C-r>-`<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with code markers (`)",
    })
    vim.keymap.set("v", "<localleader>fl", function()
        return "c[<C-r>-](<C-r>+)<Esc>"
    end, {
        expr = true,
        buffer = true,
        desc = "Wrap selected text with link ([]()), link valus is + register",
    })
    vim.keymap.set("n", "<localleader>L", wrap_bare_links_in_buffer, {
        buffer = true,
        desc = "Wrap bare URLs and file paths",
    })
    vim.keymap.set("n", "<localleader>t", toggle_markdown_list_item, {
        buffer = true,
        desc = "Toggle markdown list item",
    })
end

vim.api.nvim_buf_create_user_command(
    0,
    "MarkdownWrapBareLinks",
    wrap_bare_links_in_buffer,
    { desc = "Wrap bare URLs and file paths" }
)

vim.api.nvim_buf_create_user_command(
    0,
    "MarkdownPdf",
    generate_markdown_pdf,
    { desc = "Generate a PDF next to the current Markdown file" }
)

vim.keymap.set("n", "gO", show_toc_side, {
    buffer = true,
    silent = true,
    desc = "Show an Outline of the current buffer in a side pane",
})

setup_formatters()
