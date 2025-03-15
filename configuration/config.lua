Configuration = {
    Debug = false,
    Framework = "QBCore", --- QBCore / esx

    Command = "propcreator",
    CommandAccess = "group.admin",
    CommandDesc = "Open Prop Creator Menu",

    CommandDeleteProps = "m:propcreator:deleteprops",
    CommandDeletePropsAccess = "group.admin",
    CommandDeletePropsDesc = "Delete all props created (Security)",

    
    DistanceLoad = 50.0,


    Translations = {
        MenuTitle = "Prop Creator Menu",
        CreateProp = "Create a Prop",
        CreatePropDesc = "Spawn a new prop at your current location",
        DeleteProps = "Delete Props",
        DeletePropsDesc = "Remove all props created",

        --- Remove Prop Menu translations ---
        RemovePropsMenuTitle = "Prop Removal Menu",
        RemoveSpecificProp = "Remove a Specific Prop",
        RemoveSpecificPropDesc = "Select and remove a single placed prop",
        RemoveAllProps = "Remove All Props",
        RemoveAllPropsDesc = "Deletes every placed prop from the world", 

        PropDialogTitle = "Prop Creation",
        PropID = "Prop ID",
        PropIDDesc = "Enter the unique ID ex (prop_generator_03b).",
        PropName = "Prop Name",
        PropNameDesc = "Enter a prop name to sabe in to db (3-50 characters).",
        PropFreeze = "Freeze Prop?",
        PropFreezeDesc = "Should the prop be static and immovable?",
        PropColisions = "Collisions?",
        PropColisionsDesc = "Should the prop be able to move or interact with physics?",

        --- METADATA ---
        --- 
        Coordinates = "Coordinates",
        PropIDName = "Prop ID",
        Heading = "Heading",
        Frozen = "Frozen",
        Collisions = "Collisions",


        NoPropsOnDB = "No props found in the database.",
        ConfirmDeleteHeader = "Confirm Deletion",
        ConfirmDeleteContent = "Are you sure you want to delete ALL props?\nThis action cannot be undone.",
        --- Controls UI ---
        ControlsUI = "[Q]    - Move Up  \n" ..
                     "[E]    - Move Down  \n" ..
                     "[ARROWS] - Move  \n" ..
                     "[Scroll Wheel] - Rotate  \n" ..
                     "[LALT] - Adjust Height  \n" ..
                     "[ESC]  - Finish Editing  \n"
    }
}

