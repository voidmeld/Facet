--!strict
local Compose = require("@self/vendor/compose/core")
local Roblox = require("@self/vendor/compose/roblox")
local ControlTypes = require("@self/ui/control_types")
local createControls: ControlTypes.Factory = require("@self/ui")
local bindThemes = require("@self/ui/themes")
local InputTypes = require("@self/ui/input_types")
local NavigationTypes = require("@self/ui/navigation_types")
local RadialTypes = require("@self/ui/radial_types")
local CollectionTypes = require("@self/ui/collection_types")
local MediaTypes = require("@self/ui/media_types")
local ThemeTypes = require("@self/ui/theme_types")
local LayoutTypes = require("@self/ui/layout_types")
export type ButtonProps = InputTypes.ButtonProps
export type ToggleProps = InputTypes.ToggleProps
export type TextInputProps = InputTypes.TextInputProps
export type StepperProps = InputTypes.StepperProps
export type SliderProps = InputTypes.SliderProps
export type RatingProps = InputTypes.RatingProps
export type LevelPickerProps = InputTypes.LevelPickerProps
export type ChipProps = InputTypes.ChipProps
export type ShortcutHintProps = InputTypes.ShortcutHintProps
export type MenuItem<V = string> = NavigationTypes.MenuItem<V>
export type MenuSpec<V = string> = NavigationTypes.MenuSpec<V>
export type PickerOption<V = string> = NavigationTypes.PickerOption<V>
export type PickerSpec<V = string> = NavigationTypes.PickerSpec<V>
export type SplitButtonSpec<V = string> = NavigationTypes.SplitButtonSpec<V>
export type ComboBoxSpec = NavigationTypes.ComboBoxSpec
export type DisclosureGroupSpec = NavigationTypes.DisclosureGroupSpec
export type CollapsibleViewSpec = NavigationTypes.CollapsibleViewSpec
export type AlertAction<P = unknown> = NavigationTypes.AlertAction<P>
export type AlertSpec<P = unknown> = NavigationTypes.AlertSpec<P>
export type SheetSpec = NavigationTypes.SheetSpec
export type CalloutSpec = NavigationTypes.CalloutSpec
export type Tab = NavigationTypes.Tab
export type TabViewSpec = NavigationTypes.TabViewSpec
export type NavigationEntry<P = unknown> = NavigationTypes.NavigationEntry<P>
export type NavigationDestination<P = unknown> = NavigationTypes.NavigationDestination<P>
export type NavigationStackSpec<P = unknown> = NavigationTypes.NavigationStackSpec<P>
export type PageViewSpec = NavigationTypes.PageViewSpec
export type RadialItem<V = string> = RadialTypes.RadialItem<V>
export type RadialMenuSpec<V = string> = RadialTypes.RadialMenuSpec<V>
export type KeyedCollectionSpec<V, K> = CollectionTypes.KeyedCollectionSpec<V, K>
export type IdentityCollectionSpec<V> = CollectionTypes.IdentityCollectionSpec<V>
export type CollectionSpec<V, K> = CollectionTypes.CollectionSpec<V, K>
export type RowAction = CollectionTypes.RowAction
export type RowActionsSpec = CollectionTypes.RowActionsSpec
export type TableColumn<V, K> = CollectionTypes.TableColumn<V, K>
export type KeyedTableSpec<V, K> = CollectionTypes.KeyedTableSpec<V, K>
export type IdentityTableSpec<V> = CollectionTypes.IdentityTableSpec<V>
export type TableSpec<V, K> = CollectionTypes.TableSpec<V, K>
export type LabelProps = MediaTypes.LabelProps
export type BadgeProps = MediaTypes.BadgeProps
export type StatusIndicatorProps = MediaTypes.StatusIndicatorProps
export type ProgressViewProps = MediaTypes.ProgressViewProps
export type SkeletonProps = MediaTypes.SkeletonProps
export type ImageResource = MediaTypes.ImageResource
export type AsyncImageProps = MediaTypes.AsyncImageProps
export type AvatarProps = MediaTypes.AvatarProps
export type AvatarMember = MediaTypes.AvatarMember
export type AvatarGroupProps = MediaTypes.AvatarGroupProps
export type StageProps = MediaTypes.StageProps
export type Space = LayoutTypes.Space
export type Padding = LayoutTypes.Padding
export type Extent = LayoutTypes.Extent
export type StackProps = LayoutTypes.StackProps
export type ScreenProps = LayoutTypes.ScreenProps
export type ZStackProps = LayoutTypes.ZStackProps
export type ScrollViewProps = LayoutTypes.ScrollViewProps
export type GridProps = LayoutTypes.GridProps
export type Controls = ControlTypes.Controls
export type ControlOptions = ControlTypes.Config
export type ThemePackage = ThemeTypes.ThemePackage
export type Cell<T> = Compose.Cell<T>
export type Readable<T> = Compose.Readable<T>
export type Runtime = Compose.Runtime
export type Owner = Compose.Owner
export type Use = Compose.Use
export type ComposeModule = typeof(Compose)
export type ComposeRobloxModule = typeof(Roblox)
export type Facet = {
	VERSION: string,
	COMPOSE_COMMIT: string,
	Compose: ComposeModule,
	Roblox: ComposeRobloxModule,
	controls: (Runtime, ControlOptions?) -> Controls,
	themes: ThemeTypes.Themes,
	bind: (ComposeModule, ComposeRobloxModule) -> Facet,
}

local VERSION = "0.12.0"
local COMPOSE_COMMIT = "cbab6e0f828b68faaf676ee718cb0036c20ed935"
local USED = {
	"boundary",
	"cell",
	"cleanup",
	"createFocusScope",
	"createPool",
	"createSharedResource",
	"currentOwner",
	"formula",
	"fragment",
	"isReadable",
	"keyed",
	"portal",
	"presence",
	"sharedCell",
	"show",
	"static",
	"switch",
	"watch",
	"withOwner",
}

local function bind(core: ComposeModule, roblox: ComposeRobloxModule): Facet
	local fields = (core :: unknown) :: { [string]: unknown }
	for _, name in USED do
		if type(fields[name]) ~= "function" then
			error(
				`Facet.bind: this Compose has no function '{name}'. Facet {VERSION} supports Compose `
					.. `{string.sub(COMPOSE_COMMIT, 1, 7)} and later commits that keep the functions Facet uses.`,
				2
			)
		end
	end
	if type(roblox) ~= "table" or type(roblox.createRuntime) ~= "function" then
		error("Facet.bind: pass the Compose Roblox module from the same Compose copy as the second argument", 2)
	end
	local surface: Facet
	surface = table.freeze({
		VERSION = VERSION,
		COMPOSE_COMMIT = COMPOSE_COMMIT,
		Compose = core,
		Roblox = roblox,
		controls = function(runtime: Runtime, options: ControlOptions?): Controls
			return createControls(core, runtime, options)
		end,
		themes = bindThemes(core),
		bind = bind,
	})
	return surface
end

return bind(Compose, Roblox)
