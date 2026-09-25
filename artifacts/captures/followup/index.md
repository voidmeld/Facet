# Follow-up capture sweep

Studio playtests of `examples/virtual_monitors` (branch `parity/cap`). Real input was sent with
`UserInputService:CreateVirtualInput()` (mouse, text, Return). In the iPhone 14 emulator the
virtual mouse arrives as Touch, 47 px above the sent point; taps were corrected by measuring
`InputBegan.Position`. Desktop is `generic_handheld_1080` at 1920x1080 (mouse and keyboard, not
ten-foot). Captures are the Studio viewport scaled to 1294x728.

| Capture | What it shows | Result |
|---|---|---|
| [vm-desktop-screen-discover-dark](vm-desktop-screen-discover-dark.png) | Screen mode, Discover, dark | OK (card actions appear on hover by design) |
| [vm-desktop-screen-card-hover](vm-desktop-screen-card-hover.png) | Hover over a card shows Save and More | OK |
| [vm-desktop-screen-search-typed](vm-desktop-screen-search-typed.png) | Typed `sky` into the search combo box | OK |
| [vm-desktop-screen-detail](vm-desktop-screen-detail.png) | Game detail (full-screen alert) at 1920 wide | BUG fixed: content stretched edge to edge; BUG fixed: `UI.Divider` invisible |
| [vm-desktop-screen-launch-steps](vm-desktop-screen-launch-steps.png) | Start a private server drives the StepIndicator | BUG fixed: current-step underline crosses the state word |
| [vm-desktop-screen-date-picker-open](vm-desktop-screen-date-picker-open.png) | Play session date picker with time | BUG fixed: Hour/Minute/AM-PM row 1718 px wide in a 340 px panel |
| [vm-desktop-screen-date-picked](vm-desktop-screen-date-picked.png) | Picked Sep 26 | OK apart from the same time row |
| [vm-desktop-screen-rating-callout-hidden](vm-desktop-screen-rating-callout-hidden.png) | Rating callout presented | BUG fixed: callout painted under the modal (ZIndex 95 < 100) |
| [vm-desktop-screen-similar](vm-desktop-screen-similar.png) | Similar games with pagination | BUG fixed: About/Similar had no selected state; BUG fixed: page buttons 21-24 px wide |
| [vm-desktop-screen-saved-empty](vm-desktop-screen-saved-empty.png) | Saved shelf after unsaving | BUG fixed: empty message plus an empty table header; BUG fixed: shelves had no selected state |
| [vm-desktop-screen-chat-reply](vm-desktop-screen-chat-reply.png) | Two prompts typed and sent; reply streams (frame-sampled every 150 ms) | OK |
| [vm-desktop-screen-conversation-menu](vm-desktop-screen-conversation-menu.png) | Conversation menu | BUG fixed: checked row painted in dark onSelected text on the clear plate |
| [fix-vm-desktop-detail-column-divider-steps-callout](fix-vm-desktop-detail-column-divider-steps-callout.png) | After fix: readable column, divider, underline, callout above modal | Verified; showed the callout had no outline and the section picker pushed Save away (both fixed) |
| [vm-desktop-spatial-overview](vm-desktop-spatial-overview.png) | Spatial mode | OK; Avatar Appearance disclosure now spans its column (was 32 px short) |
| [fix-vm-spatial-chat-callout-outline](fix-vm-spatial-chat-callout-outline.png) | Focused Chat monitor, callout outlined | Verified |
| [fix-vm-spatial-chat-menu-checked-row](fix-vm-spatial-chat-menu-checked-row.png) | Checked menu row readable | Verified |
| [vm-spatial-chat-submenu-overlap](vm-spatial-chat-submenu-overlap.png) | Suggest submenu on the spatial monitor | Ancestor rows now menu rows in order (verified); OPEN: near the canvas edge the submenu is clamped over its ancestor column |
| [vm-desktop-screen-about](vm-desktop-screen-about.png) | About dialog | OK |
| [vm-desktop-screen-status-popover](vm-desktop-screen-status-popover.png) | Status popover, presence radio group | OK |
| [vm-desktop-screen-light-featured-blank](vm-desktop-screen-light-featured-blank.png) | Light mode after picking Busy | OPEN (intermittent, 1 of 6): Featured PageView page 1 sits one page off (x=1905) while CurrentPage is 1 |
| [vm-phone-portrait-discover](vm-phone-portrait-discover.png) | iPhone 14 portrait, Discover | OK |
| [vm-phone-portrait-detail](vm-phone-portrait-detail.png) | Detail on the phone | OK; OPEN (design): touch SplitButton hides alternatives behind long-press, which the emulator cannot drive |
| [vm-phone-portrait-avatar](vm-phone-portrait-avatar.png) | Avatar on the phone | OK |
| [vm-phone-portrait-chat-typing](vm-phone-portrait-chat-typing.png) | Typed into the reply field on the phone | OPEN: Disclaimer notice message cut after "leave" |
| [vm-phone-portrait-chat-notice-cut](vm-phone-portrait-chat-notice-cut.png) | Same notice after an attempted fix (reverted, not effective) | OPEN |
| [fix-vm-desktop-detail-section-pagination](fix-vm-desktop-detail-section-pagination.png) | Segmented About/Similar with Save, 44x36 page buttons | Verified |
| [fix-vm-desktop-saved-empty-shelf](fix-vm-desktop-saved-empty-shelf.png) | Saved selected, empty message only | Verified |

Transitions: Screen to Spatial and back were sampled on every RenderStepped frame. The desktop
fades over about 13 frames and the camera eases with no jumps.

Gamepad: not driven. `VirtualInput:SendKey` delivers D-pad codes as Keyboard input, which does
not move GuiService selection. The Controller Emulator opened (Gamepad1 connected), but
`VirtualInputManager:HandleGamepadButtonInput` needs RobloxScript capability and its widget
needs a real pointer on the Studio window. The gallery was not swept.
