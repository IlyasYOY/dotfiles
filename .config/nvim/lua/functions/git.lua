local core = require "functions/core"

local M = {}

-- Returns current woring branch
--- @return string? branch name if exists
function M.current_branch()
  local result = io.popen "git rev-parse --abbrev-ref HEAD"
  if not result then
    return nil
  end

  return result:read()
end

-- Resolves first remote using git remote.
--- @return string?
function M.get_first_remote()
  local result_handle = io.popen "git remote"
  if result_handle == nil then
    return nil
  end
  local lines_iterator = result_handle:lines()
  local first_remote = lines_iterator()
  return first_remote
end

-- Resolves remote url using git.
--- @param remote string? name of the remote to fetch url for.
--- @return string? url of the remote server.
function M.get_remote_url(remote)
  remote = remote or M.get_first_remote()
  if remote == nil then
    return nil
  end

  local result_handle = io.popen("git remote get-url " .. remote)
  if result_handle == nil then
    return nil
  end

  return result_handle:read()
end

-- Converts URL to link.
--- @param url string? url to convert to link.
--- @return string? url of the remote server.
function M.url_to_link(url)
  if not url then
    return nil
  end

  if core.string_has_prefix(url, "http") then
    return core.string_strip_suffix(url, ".git")
  end

  if core.string_has_prefix(url, "git@") then
    local ssh_url
    ssh_url = core.string_strip_suffix(url, ".git")
    ssh_url = core.string_strip_prefix(ssh_url, "git@")
    local split = core.string_split(ssh_url, ":")
    local server, repo = split[1], split[2]
    local server_url = "https://" .. server .. "/"
    return server_url .. repo
  end
end

-- Resolves link to current working file at remote location
--- @param link string full link to the repository: `https://github.com/IlyasYOY/python-streamer`
--- @param branch string
--- @param filepath string
--- @return string
function M.resolve_link_to_current_working_file(link, branch, filepath)
  return link .. "/blob/" .. branch .. "/" .. filepath
end

-- Resolves link to current working file at remote location
--- @param link string full link to the repository: `https://github.com/IlyasYOY/python-streamer`
--- @param branch string
--- @param filepath string
--- @param line number
--- @return string
function M.resolve_link_to_current_line(link, branch, filepath, line)
  return M.resolve_link_to_current_working_file(link, branch, filepath) .. "#L" .. line
end

return M
