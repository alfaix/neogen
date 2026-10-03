local extractors = require("neogen.utilities.extractors")
local helpers = require("neogen.utilities.helpers")
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

local class_declarations = {
    "class_definition",
    "enum_declaration",
    "mixin_declaration",
    "extension_declaration",
    "extension_type_declaration",
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

local formal_parameter_list = {
    retrieve = "first",
    node_type = "formal_parameter_list",
    subtree = {
        { retrieve = "all", node_type = "formal_parameter", subtree = parameter_tree },
        {
            retrieve = "first",
            node_type = "optional_formal_parameters",
            subtree = {
                { retrieve = "all", node_type = "formal_parameter", subtree = parameter_tree },
            },
        },
    },
}

local function extract_parameters(node, tree)
    local nodes = nodes_utils:matching_nodes_from(node, tree)
    local res = extractors:extract_from_matched(nodes)

    -- Wildcard parameters cannot be referenced, so there is nothing to document
    local parameters = vim.tbl_filter(function(name)
        return name ~= "_"
    end, res[i.Parameter] or {})

    return { [i.Parameter] = #parameters > 0 and parameters or nil }
end

return {
    parent = {
        func = function_signatures,
        class = class_declarations,
    },
    data = {
        func = {
            [table.concat(function_signatures, "|")] = {
                ["0"] = {
                    extract = function(node)
                        return extract_parameters(node, { formal_parameter_list })
                    end,
                },
            },
        },
        class = {
            [table.concat(class_declarations, "|")] = {
                ["0"] = {
                    extract = function(node)
                        -- The representation of an extension type is a primary constructor with a single parameter
                        local representation = node:field("representation")[1]
                        if representation then
                            return { [i.Parameter] = helpers.get_node_text(representation:field("name")[1]) }
                        end

                        return extract_parameters(node, {
                            {
                                retrieve = "first",
                                node_type = "primary_constructor",
                                subtree = { formal_parameter_list },
                            },
                        })
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
