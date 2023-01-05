
-- reloads package with specified name.
function G_R(package_name)
    package.loaded = nil
    return require(package_name)
end

-- prints pretty table and returns it back
function G_P(table)
    print(vim.inspect(table))
    return table
end
