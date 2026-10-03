local default_locator = require("neogen.locators.default")

---@param node_info Neogen.node_info
---@param nodes_to_match TSNode[]
---@return TSNode?
return function(node_info, nodes_to_match)
    -- In the dart parser, function bodies and constructor initializers are not children of their signature
    -- but its siblings, so we need to jump back to the signature when the cursor is inside one of them
    local node = node_info.current
    while node and not vim.tbl_contains({ "function_body", "method_signature", "declaration" }, node:type()) do
        node = node:parent()
    end

    if node and node:type() == "function_body" then
        node = node:prev_named_sibling()
    end

    if node and vim.tbl_contains({ "method_signature", "declaration" }, node:type()) then
        node_info.current = node:named_child(0) or node_info.current
    elseif node then
        node_info.current = node
    end

    return default_locator(node_info, nodes_to_match)
end
