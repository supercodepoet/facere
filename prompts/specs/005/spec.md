# Definition

We have built the main portion of our application but have missed a big piece of the feature set. On our TODO List items we can assign different people to the item, notify different people on the item when complete, different people can comment on an item. We currently do not support multiple people on a TODO list or items. We need a way to collaborate on a TODO List or set of lists and the items within them. I don't think I want users to be parts of organizations for that type of setup. Maybe we create workspaces that users can be apart of or we keep it simple and just give the ability to invite someone to an TODO List. What would be the best approach?

# Requirements

- We need to allow multiple folks to collaborate on a TODO List and TODO List Item
- We need to provide a way to invite folks to collaborate
- We need a way to remove folks from collaborating but keep their past interactions
- We need to be able to assign collaboratiors to a TODO List Item
- We need to be able to notify set collaborators when an TODO List Item is Done
- We need to allow collaborators to leave comments and replies on a TODO List Item
- We need a way to manage if a collaborator can change the Note, Status, Priority, Tags, etc of a TODO List Item


Again, use the *.pen files as the source of truth and visual reference on the UI/UX and business flow of this feature. Ask for anything that is unclear or make recommendations for this feature. For any decisions we make, make sure to flow those back into the *.pen files.A