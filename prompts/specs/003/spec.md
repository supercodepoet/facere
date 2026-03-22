# Definition

We need to flesh out the creation and management of TODO list items. We are going to use the
`todo-list-item-screens.pen` as the visual reference and the source of truth for fields and flows. You
can also refer to `initial-screens.pen` for visual reference for this application. We are going to
support the following actions:
- Create a section
- Create an item
- Rearrange a section and with all items
- Rearrange items within a section
- Rearrange items within a TODO list
- Move items between sections or outside a section
- Edit a section
- Edit an item
- View the details of an item

We want creation of sections and items to be extremely fast so users can fill out a TODO list quickly
and encourage application use. The user then can take time to manage their TODO list layout, sections,
ordering, etc. They can also add additional information to a TODO item that will flesh it out. All these
fields and interactions are in the `todo-list-item-screens.pen` with proper context menus to implement. If you
have questions on fields or interactions refer to the visual reference.

# Requirements

Make sure to implement:
- Adding First Item - Inline
- Adding Section - Inline
- List With Items & Sections
- TODO List Detail
- TODO Item Detail