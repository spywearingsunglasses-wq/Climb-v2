local urls = {
    "https://raw.githubusercontent.com/spywearingsunglasses-wq/Climb-v2/refs/heads/main/Part%201.lua",
    "https://raw.githubusercontent.com/spywearingsunglasses-wq/Climb-v2/refs/heads/main/Part%202.lua",
    "https://raw.githubusercontent.com/spywearingsunglasses-wq/Climb-v2/refs/heads/main/Part%203.lua",
  "https://raw.githubusercontent.com/spywearingsunglasses-wq/Climb-v2/refs/heads/main/Part%204.%20(Optional)"
}

for i, url in ipairs(urls) do
    local ok, src = pcall(game.HttpGet, game, url)
    if ok and src then
        local fn, err = loadstring(src)
        if fn then
            fn()
        else
            warn("Part " .. i .. " syntax error:", err)
        end
    else
        warn("Failed to fetch Part " .. i .. ":", src)
    end
end
