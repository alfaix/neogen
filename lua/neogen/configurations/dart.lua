local extractors = require("neogen.utilities.extractors")
local i = require("neogen.types.template").item
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.template")

local function_signatures = {
    "function_signature",
    "getter_signature",
    "setter_signature",
    "operator_signature",
    "constructor_signature",
    "constant_constructor_signature",
    "factory_constructor_signature",
    "redirecting_factory_constructor_signature",
}

local parameter_tree = {
    { retrieve = "first", node_type = "identifier", extract = true, as = i.Parameter },
    {
        retrieve = "first",
        node_type = "constructor_param|super_formal_parameter",
        subtree = {
            { retrieve = "first", node_type = "identifier", extract = true, as = i.Parameter },
        },
    },
}

return {
    parent = {
        func = function_signatures,
        class = { "class_definition", "enum_declaration", "mixin_declaration", "extension_declaration" },
    },
    data = {
        func = {
            [table.concat(function_signatures, "|")] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                retrieve = "first",
                                node_type = "formal_parameter_list",
                                subtree = {
                                    { retrieve = "all", node_type = "formal_parameter", subtree = parameter_tree },
                                    {
                                        retrieve = "first",
                                        node_type = "optional_formal_parameters",
                                        subtree = {
                                            {
                                                retrieve = "all",
                                                node_type = "formal_parameter",
                                                subtree = parameter_tree,
                                            },
                                        },
                                    },
                                },
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
        class = {
            ["class_definition|enum_declaration|mixin_declaration|extension_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    locator = require("neogen.locators.dart"),

    template = template
        :config({
            position = function(node)
                -- Class members are wrapped in another node, and their annotations are previous siblings
                local parent = node:parent()
                if parent and vim.tbl_contains({ "method_signature", "declaration" }, parent:type()) then
                    node = parent
                end

                while node:prev_named_sibling() and node:prev_named_sibling():type() == "annotation" do
                    node = node:prev_named_sibling()
                end

                local row, col = vim.treesitter.get_node_range(node)
                return row, col
            end,
        })
        :add_default_annotation("dartdoc"),
}
