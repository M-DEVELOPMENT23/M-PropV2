Config = {}

Config.DebugMode = true

Config.OpenMenuCommand = "propcreator"

Config.DeleteOnStop = true -- Deletes props when stopping the script (prevents ghost props)

Config.Placement = {
    CooldownMs = 1000,
    PreviewAlpha = 200,
    AutoSnapToGround = true,
    DefaultSnapMove = 0.5,
    DefaultSnapRot = 45.0,
}

Config.Streaming = {
    SpawnRadius = 150.0,   -- Distance to spawn entity
    DespawnRadius = 180.0, -- Distance to despawn entity
    GridSize = 45.0,       -- Map cell size
    FadeIn = true          -- Smooth fade-in effect
}

Config.MassDeleteDelay = 150 -- Ms between deletions to avoid server overload

Config.UseTarget = true 
Config.TargetIcons = {
    Edit = 'fa-solid fa-pen-ruler',
    Duplicate = 'fa-solid fa-copy',
    Delete = 'fa-solid fa-trash'
}

Config.Lang = {
    -- Notifications
    NoPerms = "Access denied.",
    ModelInvalid = "Invalid or unloaded model.",
    Created = "Prop created successfully.",
    Updated = "Prop updated successfully.",
    Deleted = "Prop deleted.",
    DeleteFail = "Failed to delete Prop ID: %s",
    MassDeleteStart = "Starting mass deletion...",
    MassDeleteDone = "Process finished. Deleted: %d/%d",
    NothingFound = "No props found nearby.",
    Undo = "Action undone.",
    Copied = "Data copied to clipboard.",
    
    -- Menus
    MenuTitle = "Prop Creator Ultimate",
    EditorMode = "Editor Mode",
    EditorDesc = "Enable visualization and editing",
    NewProp = "New Prop",
    AdvTools = "Advanced Tools",
    AdvDesc = "Mass delete, radius tools, lists",
    UndoLast = "Undo last action",
    History = "History: %d actions",
    
    -- Inputs
    InputModel = "Model Name (e.g. prop_bench_01)",
    InputFreeze = "Freeze",
    InputCol = "Collision",
    InputSnap = "Snap to ground",
    InputRadius = "Radius (meters)",
    
    -- Actions
    SearchProps = "Search within radius",
    DeleteAllRadius = "Delete ALL within Radius",
    DeleteModelRadius = "Delete MODEL within Radius",
    DeleteWarning = "THIS IS PERMANENT. Confirm?",
    Teleport = "Teleport",
    EditGizmo = "Edit (Gizmo)",
    DeleteProp = "Delete",
    CopyCoords = "Copy Coordinates",
    
    -- UI
    PropInfo = "**ID:** %s  \n**MODEL:** %s",
    DeletingUI = "Deleting... %d/%d"
}
