# Practical recipes

## Confirm a destructive command

Keep the presentation state in a cell. The Alert dismisses before it calls the
selected action. Then it restores the previous selection if that object still
exists.

```luau
local confirm = Compose.cell(false)
return UI.VStack {
    UI.Button { label = "Delete", onActivate = function() confirm:set(true) end },
    UI.Alert {
        isPresented = confirm,
        title = "Delete this draft?",
        message = "This removes the saved draft.",
        actions = {
            { id = "cancel", label = "Keep draft", role = "cancel" },
            { id = "delete", label = "Delete", role = "destructive", onActivate = deleteDraft },
        },
    },
}
```

## Filter a large list

```luau
local query = Compose.cell("")
local visible = Compose.formula(function(use)
    local term = string.lower(use(query))
    local result = {}
    for _, item in use(items) do
        if string.find(string.lower(item.title), term, 1, true) then
            table.insert(result, item)
        end
    end
    return result
end)
local list = UI.VirtualList {
    from = visible,
    key = function(item) return item.id end,
    itemSize = 48,
    render = function(current)
        return UI.Button {
            label = function(use) return use(current).title end,
            onActivate = function() openItem(current:peek().id) end,
            Size = UDim2.new(1, 0, 0, 48),
            AutomaticSize = Enum.AutomaticSize.None,
        }
    end,
}
```

Mount `list` next to a TextInput that is bound to `query`. Use native layout.
Keep the selected ids and the row drafts in the shared model. Let Compose keep
the collection anchor after filtering and sorting.

## Keep a drill-down path

```luau
local path = Compose.cell({})
return UI.NavigationStack {
    path = path,
    root = { title = "Catalog", content = Catalog },
    destinations = {
        item = {
            title = "Details",
            content = function(entry) return ItemDetails(entry.value) end,
        },
    },
}
```

Push `{ id = "item", value = itemId }` into `path` from the catalog action. The
control uses Compose `LayerStack` and owns the Back behavior. Do not keep a
separate presenter stack.
