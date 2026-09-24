--!strict
local Compose = require("../vendor/compose/core")

export type Value<T> = Compose.Given<T>
export type StaticValue = typeof(Compose.static(nil))
export type Constructor<P, N> = ((P) -> N) & ((string) -> (P) -> N)
export type AttributeValue =
	string
	| boolean
	| number
	| UDim
	| UDim2
	| BrickColor
	| Color3
	| Vector2
	| Vector3
	| CFrame
	| NumberSequence
	| ColorSequence
	| NumberRange
	| Rect
	| Font
export type Attributes = { [string]: Value<AttributeValue?> }

type BasePartOptionalValue = Value<BasePart?>
type BooleanValue = Value<boolean>
type CFrameValue = Value<CFrame>
type CameraValue = Value<Camera>
type Color3Value = Value<Color3>
type ColorSequenceValue = Value<ColorSequence>
type ContentValue = Value<Content>
type EnumApplyStrokeModeValue = Value<Enum.ApplyStrokeMode>
type EnumAspectTypeValue = Value<Enum.AspectType>
type EnumAutomaticSizeValue = Value<Enum.AutomaticSize>
type EnumBorderModeValue = Value<Enum.BorderMode>
type EnumBorderStrokePositionValue = Value<Enum.BorderStrokePosition>
type EnumButtonStyleValue = Value<Enum.ButtonStyle>
type EnumCameraTypeValue = Value<Enum.CameraType>
type EnumDominantAxisValue = Value<Enum.DominantAxis>
type EnumEasingDirectionValue = Value<Enum.EasingDirection>
type EnumEasingStyleValue = Value<Enum.EasingStyle>
type EnumElasticBehaviorValue = Value<Enum.ElasticBehavior>
type EnumFieldOfViewModeValue = Value<Enum.FieldOfViewMode>
type EnumFillDirectionValue = Value<Enum.FillDirection>
type EnumFontValue = Value<Enum.Font>
type EnumFrameStyleValue = Value<Enum.FrameStyle>
type EnumGradientTileModeValue = Value<Enum.GradientTileMode>
type EnumGradientTypeValue = Value<Enum.GradientType>
type EnumHorizontalAlignmentValue = Value<Enum.HorizontalAlignment>
type EnumInputActionTypeValue = Value<Enum.InputActionType>
type EnumInputBindingTypeValue = Value<Enum.InputBindingType>
type EnumInputSinkValue = Value<Enum.InputSink>
type EnumItemLineAlignmentValue = Value<Enum.ItemLineAlignment>
type EnumKeyCodeValue = Value<Enum.KeyCode>
type EnumLineJoinModeValue = Value<Enum.LineJoinMode>
type EnumModelStreamingModeValue = Value<Enum.ModelStreamingMode>
type EnumNormalIdValue = Value<Enum.NormalId>
type EnumResamplerModeValue = Value<Enum.ResamplerMode>
type EnumSafeAreaCompatibilityValue = Value<Enum.SafeAreaCompatibility>
type EnumScaleTypeValue = Value<Enum.ScaleType>
type EnumScreenInsetsValue = Value<Enum.ScreenInsets>
type EnumScrollBarInsetValue = Value<Enum.ScrollBarInset>
type EnumScrollingDirectionValue = Value<Enum.ScrollingDirection>
type EnumSelectionBehaviorValue = Value<Enum.SelectionBehavior>
type EnumSizeConstraintValue = Value<Enum.SizeConstraint>
type EnumSortOrderValue = Value<Enum.SortOrder>
type EnumStrokeSizingModeValue = Value<Enum.StrokeSizingMode>
type EnumSurfaceGuiSizingModeValue = Value<Enum.SurfaceGuiSizingMode>
type EnumTextDirectionValue = Value<Enum.TextDirection>
type EnumTextTruncateValue = Value<Enum.TextTruncate>
type EnumTextXAlignmentValue = Value<Enum.TextXAlignment>
type EnumTextYAlignmentValue = Value<Enum.TextYAlignment>
type EnumUIDragDetectorBoundingBehaviorValue = Value<Enum.UIDragDetectorBoundingBehavior>
type EnumUIDragDetectorDragRelativityValue = Value<Enum.UIDragDetectorDragRelativity>
type EnumUIDragDetectorDragSpaceValue = Value<Enum.UIDragDetectorDragSpace>
type EnumUIDragDetectorDragStyleValue = Value<Enum.UIDragDetectorDragStyle>
type EnumUIDragDetectorResponseStyleValue = Value<Enum.UIDragDetectorResponseStyle>
type EnumUIDragSpeedAxisMappingValue = Value<Enum.UIDragSpeedAxisMapping>
type EnumUIFlexAlignmentValue = Value<Enum.UIFlexAlignment>
type EnumUIFlexModeValue = Value<Enum.UIFlexMode>
type EnumVerticalAlignmentValue = Value<Enum.VerticalAlignment>
type EnumVerticalScrollBarPositionValue = Value<Enum.VerticalScrollBarPosition>
type EnumZIndexBehaviorValue = Value<Enum.ZIndexBehavior>
type FontValue = Value<Font>
type GuiBase2dValue = Value<GuiBase2d>
type GuiButtonValue = Value<GuiButton>
type GuiObjectValue = Value<GuiObject>
type HapticEffectValue = Value<HapticEffect>
type HumanoidBasePartNilValue = Value<Humanoid | BasePart | nil>
type InstanceOptionalValue = Value<Instance?>
type InstanceValue = Value<Instance>
type LocalizationTableValue = Value<LocalizationTable>
type NumberSequenceValue = Value<NumberSequence>
type NumberValue = Value<number>
type RectValue = Value<Rect>
type SecurityCapabilitiesValue = Value<SecurityCapabilities>
type StringValue = Value<string>
type UDim2Value = Value<UDim2>
type UDimValue = Value<UDim>
type Vector2Value = Value<Vector2>
type Vector3Value = Value<Vector3>

export type ObjectProperties = {
	Changed: ((string) -> ())?,
}
export type ObjectNativeProps = ObjectProperties & { [number]: Compose.Child }
export type ObjectProps = ObjectNativeProps & { ref: ((Object) -> ())? }

export type InstanceProperties = ObjectProperties & {
	Attributes: Attributes?,
	AncestryChanged: ((Instance, Instance?) -> ())?,
	Archivable: BooleanValue?,
	AttributeChanged: ((string) -> ())?,
	Capabilities: SecurityCapabilitiesValue?,
	ChildAdded: ((Instance) -> ())?,
	ChildRemoved: ((Instance) -> ())?,
	DescendantAdded: ((Instance) -> ())?,
	DescendantRemoving: ((Instance) -> ())?,
	Destroying: (() -> ())?,
	Name: StringValue?,
	Parent: (InstanceOptionalValue | StaticValue)?,
	Sandboxed: BooleanValue?,
	StyledPropertiesChanged: (() -> ())?,
}
export type InstanceNativeProps = InstanceProperties & { [number]: Compose.Child }
export type InstanceProps = InstanceNativeProps & { ref: ((Instance) -> ())? }

export type GuiBaseProperties = InstanceProperties & {}
export type GuiBaseNativeProps = GuiBaseProperties & { [number]: Compose.Child }
export type GuiBaseProps = GuiBaseNativeProps & { ref: ((GuiBase) -> ())? }

export type GuiBase2dProperties = GuiBaseProperties & {
	AutoLocalize: BooleanValue?,
	RootLocalizationTable: (LocalizationTableValue | StaticValue)?,
	SelectionBehaviorDown: EnumSelectionBehaviorValue?,
	SelectionBehaviorLeft: EnumSelectionBehaviorValue?,
	SelectionBehaviorRight: EnumSelectionBehaviorValue?,
	SelectionBehaviorUp: EnumSelectionBehaviorValue?,
	SelectionChanged: ((boolean, GuiObject, GuiObject) -> ())?,
	SelectionGroup: BooleanValue?,
}
export type GuiBase2dNativeProps = GuiBase2dProperties & { [number]: Compose.Child }
export type GuiBase2dProps = GuiBase2dNativeProps & { ref: ((GuiBase2d) -> ())? }

export type LayerCollectorProperties = GuiBase2dProperties & {
	Enabled: BooleanValue?,
	ResetOnSpawn: BooleanValue?,
	ZIndexBehavior: EnumZIndexBehaviorValue?,
}
export type LayerCollectorNativeProps = LayerCollectorProperties & { [number]: Compose.Child }
export type LayerCollectorProps = LayerCollectorNativeProps & { ref: ((LayerCollector) -> ())? }

export type BillboardGuiProperties = LayerCollectorProperties & {
	Active: BooleanValue?,
	Adornee: (InstanceValue | StaticValue)?,
	AlwaysOnTop: BooleanValue?,
	Brightness: NumberValue?,
	ClipsDescendants: BooleanValue?,
	DistanceStep: NumberValue?,
	ExtentsOffset: Vector3Value?,
	ExtentsOffsetWorldSpace: Vector3Value?,
	LightInfluence: NumberValue?,
	MaxDistance: NumberValue?,
	PlayerToHideFrom: (InstanceValue | StaticValue)?,
	Size: UDim2Value?,
	SizeOffset: Vector2Value?,
	StudsOffset: Vector3Value?,
	StudsOffsetWorldSpace: Vector3Value?,
}
export type BillboardGuiNativeProps = BillboardGuiProperties & { [number]: Compose.Child }
export type BillboardGuiProps = BillboardGuiNativeProps & { ref: ((BillboardGui) -> ())? }

export type PVInstanceProperties = InstanceProperties & {}
export type PVInstanceNativeProps = PVInstanceProperties & { [number]: Compose.Child }
export type PVInstanceProps = PVInstanceNativeProps & { ref: ((PVInstance) -> ())? }

export type CameraProperties = PVInstanceProperties & {
	CFrame: CFrameValue?,
	CameraSubject: (HumanoidBasePartNilValue | StaticValue)?,
	CameraType: EnumCameraTypeValue?,
	DiagonalFieldOfView: NumberValue?,
	FieldOfView: NumberValue?,
	FieldOfViewMode: EnumFieldOfViewModeValue?,
	Focus: CFrameValue?,
	HeadLocked: BooleanValue?,
	HeadScale: NumberValue?,
	InterpolationFinished: (() -> ())?,
	MaxAxisFieldOfView: NumberValue?,
	VRTiltAndRollEnabled: BooleanValue?,
}
export type CameraNativeProps = CameraProperties & { [number]: Compose.Child }
export type CameraProps = CameraNativeProps & { ref: ((Camera) -> ())? }

export type GuiObjectProperties = GuiBase2dProperties & {
	Active: BooleanValue?,
	AnchorPoint: Vector2Value?,
	AutomaticSize: EnumAutomaticSizeValue?,
	BackgroundColor3: Color3Value?,
	BackgroundTransparency: NumberValue?,
	BorderColor3: Color3Value?,
	BorderMode: EnumBorderModeValue?,
	BorderSizePixel: NumberValue?,
	ClipsDescendants: BooleanValue?,
	InputBegan: ((InputObject) -> ())?,
	InputChanged: ((InputObject) -> ())?,
	InputEnded: ((InputObject) -> ())?,
	InputSink: EnumInputSinkValue?,
	Interactable: BooleanValue?,
	LayoutOrder: NumberValue?,
	MouseEnter: ((number, number) -> ())?,
	MouseLeave: ((number, number) -> ())?,
	MouseMoved: ((number, number) -> ())?,
	MouseWheelBackward: ((number, number) -> ())?,
	MouseWheelForward: ((number, number) -> ())?,
	NextSelectionDown: (GuiObjectValue | StaticValue)?,
	NextSelectionLeft: (GuiObjectValue | StaticValue)?,
	NextSelectionRight: (GuiObjectValue | StaticValue)?,
	NextSelectionUp: (GuiObjectValue | StaticValue)?,
	Position: UDim2Value?,
	Rotation: NumberValue?,
	Selectable: BooleanValue?,
	SelectionGained: (() -> ())?,
	SelectionImageObject: (GuiObjectValue | StaticValue)?,
	SelectionLost: (() -> ())?,
	SelectionOrder: NumberValue?,
	Size: UDim2Value?,
	SizeConstraint: EnumSizeConstraintValue?,
	TouchLongPress: (({ Vector2 }, Enum.UserInputState) -> ())?,
	TouchPan: (({ Vector2 }, Vector2, Vector2, Enum.UserInputState) -> ())?,
	TouchPinch: (({ Vector2 }, number, number, Enum.UserInputState) -> ())?,
	TouchRotate: (({ Vector2 }, number, number, Enum.UserInputState) -> ())?,
	TouchSwipe: ((Enum.SwipeDirection, number) -> ())?,
	TouchTap: (({ Vector2 }) -> ())?,
	Visible: BooleanValue?,
	ZIndex: NumberValue?,
}
export type GuiObjectNativeProps = GuiObjectProperties & { [number]: Compose.Child }
export type GuiObjectProps = GuiObjectNativeProps & { ref: ((GuiObject) -> ())? }

export type CanvasGroupProperties = GuiObjectProperties & {
	GroupColor3: Color3Value?,
	GroupTransparency: NumberValue?,
}
export type CanvasGroupNativeProps = CanvasGroupProperties & { [number]: Compose.Child }
export type CanvasGroupProps = CanvasGroupNativeProps & { ref: ((CanvasGroup) -> ())? }

export type FolderProperties = InstanceProperties & {}
export type FolderNativeProps = FolderProperties & { [number]: Compose.Child }
export type FolderProps = FolderNativeProps & { ref: ((Folder) -> ())? }

export type FrameProperties = GuiObjectProperties & {
	Style: EnumFrameStyleValue?,
}
export type FrameNativeProps = FrameProperties & { [number]: Compose.Child }
export type FrameProps = FrameNativeProps & { ref: ((Frame) -> ())? }

export type GuiButtonProperties = GuiObjectProperties & {
	Activated: ((InputObject, number) -> ())?,
	AutoButtonColor: BooleanValue?,
	HoverHapticEffect: (HapticEffectValue | StaticValue)?,
	Modal: BooleanValue?,
	MouseButton1Click: (() -> ())?,
	MouseButton1Down: ((number, number) -> ())?,
	MouseButton1Up: ((number, number) -> ())?,
	MouseButton2Click: (() -> ())?,
	MouseButton2Down: ((number, number) -> ())?,
	MouseButton2Up: ((number, number) -> ())?,
	PressHapticEffect: (HapticEffectValue | StaticValue)?,
	SecondaryActivated: ((InputObject) -> ())?,
	Selected: BooleanValue?,
	Style: EnumButtonStyleValue?,
}
export type GuiButtonNativeProps = GuiButtonProperties & { [number]: Compose.Child }
export type GuiButtonProps = GuiButtonNativeProps & { ref: ((GuiButton) -> ())? }

export type ImageButtonProperties = GuiButtonProperties & {
	HoverImage: StringValue?,
	HoverImageContent: ContentValue?,
	Image: StringValue?,
	ImageColor3: Color3Value?,
	ImageContent: ContentValue?,
	ImageRectOffset: Vector2Value?,
	ImageRectSize: Vector2Value?,
	ImageTransparency: NumberValue?,
	PressedImage: StringValue?,
	PressedImageContent: ContentValue?,
	ResampleMode: EnumResamplerModeValue?,
	ScaleType: EnumScaleTypeValue?,
	SliceCenter: RectValue?,
	SliceScale: NumberValue?,
	TileSize: UDim2Value?,
}
export type ImageButtonNativeProps = ImageButtonProperties & { [number]: Compose.Child }
export type ImageButtonProps = ImageButtonNativeProps & { ref: ((ImageButton) -> ())? }

export type GuiLabelProperties = GuiObjectProperties & {}
export type GuiLabelNativeProps = GuiLabelProperties & { [number]: Compose.Child }
export type GuiLabelProps = GuiLabelNativeProps & { ref: ((GuiLabel) -> ())? }

export type ImageLabelProperties = GuiLabelProperties & {
	Image: StringValue?,
	ImageColor3: Color3Value?,
	ImageContent: ContentValue?,
	ImageRectOffset: Vector2Value?,
	ImageRectSize: Vector2Value?,
	ImageTransparency: NumberValue?,
	ResampleMode: EnumResamplerModeValue?,
	ScaleType: EnumScaleTypeValue?,
	SliceCenter: RectValue?,
	SliceScale: NumberValue?,
	TileSize: UDim2Value?,
}
export type ImageLabelNativeProps = ImageLabelProperties & { [number]: Compose.Child }
export type ImageLabelProps = ImageLabelNativeProps & { ref: ((ImageLabel) -> ())? }

export type InputActionProperties = InstanceProperties & {
	Enabled: BooleanValue?,
	Pressed: (() -> ())?,
	Released: (() -> ())?,
	StateChanged: ((unknown) -> ())?,
	Type: EnumInputActionTypeValue?,
}
export type InputActionNativeProps = InputActionProperties & { [number]: Compose.Child }
export type InputActionProps = InputActionNativeProps & { ref: ((InputAction) -> ())? }

export type InputBindingProperties = InstanceProperties & {
	Backward: EnumKeyCodeValue?,
	ClampMagnitudeToOne: BooleanValue?,
	DisplayImage: ContentValue?,
	DisplayName: StringValue?,
	Down: EnumKeyCodeValue?,
	Forward: EnumKeyCodeValue?,
	KeyCode: EnumKeyCodeValue?,
	Left: EnumKeyCodeValue?,
	PointerIndex: NumberValue?,
	PressedThreshold: NumberValue?,
	PrimaryModifier: EnumKeyCodeValue?,
	ReleasedThreshold: NumberValue?,
	ResponseCurve: NumberValue?,
	Right: EnumKeyCodeValue?,
	Scale: NumberValue?,
	SecondaryModifier: EnumKeyCodeValue?,
	Type: EnumInputBindingTypeValue?,
	UIButton: (GuiButtonValue | StaticValue)?,
	UIModifier: (GuiButtonValue | StaticValue)?,
	Up: EnumKeyCodeValue?,
	Vector2Scale: Vector2Value?,
	Vector3Scale: Vector3Value?,
}
export type InputBindingNativeProps = InputBindingProperties & { [number]: Compose.Child }
export type InputBindingProps = InputBindingNativeProps & { ref: ((InputBinding) -> ())? }

export type InputContextProperties = InstanceProperties & {
	Enabled: BooleanValue?,
	Priority: NumberValue?,
	Sink: BooleanValue?,
}
export type InputContextNativeProps = InputContextProperties & { [number]: Compose.Child }
export type InputContextProps = InputContextNativeProps & { ref: ((InputContext) -> ())? }

export type Path2DProperties = GuiBaseProperties & {
	Closed: BooleanValue?,
	Color3: Color3Value?,
	ControlPointChanged: (() -> ())?,
	Thickness: NumberValue?,
	Visible: BooleanValue?,
	ZIndex: NumberValue?,
}
export type Path2DNativeProps = Path2DProperties & { [number]: Compose.Child }
export type Path2DProps = Path2DNativeProps & { ref: ((Path2D) -> ())? }

export type ScreenGuiProperties = LayerCollectorProperties & {
	ClipToDeviceSafeArea: BooleanValue?,
	DisplayOrder: NumberValue?,
	IgnoreGuiInset: BooleanValue?,
	SafeAreaCompatibility: EnumSafeAreaCompatibilityValue?,
	ScreenInsets: EnumScreenInsetsValue?,
}
export type ScreenGuiNativeProps = ScreenGuiProperties & { [number]: Compose.Child }
export type ScreenGuiProps = ScreenGuiNativeProps & { ref: ((ScreenGui) -> ())? }

export type ScrollingFrameProperties = GuiObjectProperties & {
	AutomaticCanvasSize: EnumAutomaticSizeValue?,
	BottomImage: StringValue?,
	BottomImageContent: ContentValue?,
	CanvasPosition: Vector2Value?,
	CanvasSize: UDim2Value?,
	ElasticBehavior: EnumElasticBehaviorValue?,
	HorizontalScrollBarInset: EnumScrollBarInsetValue?,
	MidImage: StringValue?,
	MidImageContent: ContentValue?,
	ScrollBarImageColor3: Color3Value?,
	ScrollBarImageTransparency: NumberValue?,
	ScrollBarThickness: NumberValue?,
	ScrollingDirection: EnumScrollingDirectionValue?,
	ScrollingEnabled: BooleanValue?,
	TopImage: StringValue?,
	TopImageContent: ContentValue?,
	VerticalScrollBarInset: EnumScrollBarInsetValue?,
	VerticalScrollBarPosition: EnumVerticalScrollBarPositionValue?,
}
export type ScrollingFrameNativeProps = ScrollingFrameProperties & { [number]: Compose.Child }
export type ScrollingFrameProps = ScrollingFrameNativeProps & { ref: ((ScrollingFrame) -> ())? }

export type StyleBaseProperties = InstanceProperties & {
	StyleRulesChanged: (() -> ())?,
}
export type StyleBaseNativeProps = StyleBaseProperties & { [number]: Compose.Child }
export type StyleBaseProps = StyleBaseNativeProps & { ref: ((StyleBase) -> ())? }

export type StyleRuleProperties = StyleBaseProperties & {
	Priority: NumberValue?,
	Selector: StringValue?,
}
export type StyleRuleNativeProps = StyleRuleProperties & { [number]: Compose.Child }
export type StyleRuleProps = StyleRuleNativeProps & { ref: ((StyleRule) -> ())? }

export type StyleSheetProperties = StyleBaseProperties & {}
export type StyleSheetNativeProps = StyleSheetProperties & { [number]: Compose.Child }
export type StyleSheetProps = StyleSheetNativeProps & { ref: ((StyleSheet) -> ())? }

export type SurfaceGuiBaseProperties = LayerCollectorProperties & {
	Active: BooleanValue?,
	Adornee: (InstanceValue | StaticValue)?,
	Face: EnumNormalIdValue?,
}
export type SurfaceGuiBaseNativeProps = SurfaceGuiBaseProperties & { [number]: Compose.Child }
export type SurfaceGuiBaseProps = SurfaceGuiBaseNativeProps & { ref: ((SurfaceGuiBase) -> ())? }

export type SurfaceGuiProperties = SurfaceGuiBaseProperties & {
	AlwaysOnTop: BooleanValue?,
	Brightness: NumberValue?,
	CanvasSize: Vector2Value?,
	ClipsDescendants: BooleanValue?,
	LightInfluence: NumberValue?,
	MaxDistance: NumberValue?,
	PixelsPerStud: NumberValue?,
	SizingMode: EnumSurfaceGuiSizingModeValue?,
	ToolPunchThroughDistance: NumberValue?,
	ZOffset: NumberValue?,
}
export type SurfaceGuiNativeProps = SurfaceGuiProperties & { [number]: Compose.Child }
export type SurfaceGuiProps = SurfaceGuiNativeProps & { ref: ((SurfaceGui) -> ())? }

export type TextBoxProperties = GuiObjectProperties & {
	ClearTextOnFocus: BooleanValue?,
	CursorPosition: NumberValue?,
	FocusLost: ((boolean, InputObject) -> ())?,
	Focused: (() -> ())?,
	Font: EnumFontValue?,
	FontFace: FontValue?,
	LineHeight: NumberValue?,
	MaxVisibleGraphemes: NumberValue?,
	MultiLine: BooleanValue?,
	OpenTypeFeatures: StringValue?,
	PlaceholderColor3: Color3Value?,
	PlaceholderText: StringValue?,
	ReturnPressedFromOnScreenKeyboard: (() -> ())?,
	RichText: BooleanValue?,
	SelectionStart: NumberValue?,
	ShowNativeInput: BooleanValue?,
	Text: StringValue?,
	TextColor3: Color3Value?,
	TextDirection: EnumTextDirectionValue?,
	TextEditable: BooleanValue?,
	TextScaled: BooleanValue?,
	TextSize: NumberValue?,
	TextStrokeColor3: Color3Value?,
	TextStrokeTransparency: NumberValue?,
	TextTransparency: NumberValue?,
	TextTruncate: EnumTextTruncateValue?,
	TextWrapped: BooleanValue?,
	TextXAlignment: EnumTextXAlignmentValue?,
	TextYAlignment: EnumTextYAlignmentValue?,
}
export type TextBoxNativeProps = TextBoxProperties & { [number]: Compose.Child }
export type TextBoxProps = TextBoxNativeProps & { ref: ((TextBox) -> ())? }

export type TextButtonProperties = GuiButtonProperties & {
	Font: EnumFontValue?,
	FontFace: FontValue?,
	LineHeight: NumberValue?,
	MaxVisibleGraphemes: NumberValue?,
	OpenTypeFeatures: StringValue?,
	RichText: BooleanValue?,
	Text: StringValue?,
	TextColor3: Color3Value?,
	TextDirection: EnumTextDirectionValue?,
	TextScaled: BooleanValue?,
	TextSize: NumberValue?,
	TextStrokeColor3: Color3Value?,
	TextStrokeTransparency: NumberValue?,
	TextTransparency: NumberValue?,
	TextTruncate: EnumTextTruncateValue?,
	TextWrapped: BooleanValue?,
	TextXAlignment: EnumTextXAlignmentValue?,
	TextYAlignment: EnumTextYAlignmentValue?,
}
export type TextButtonNativeProps = TextButtonProperties & { [number]: Compose.Child }
export type TextButtonProps = TextButtonNativeProps & { ref: ((TextButton) -> ())? }

export type TextLabelProperties = GuiLabelProperties & {
	Font: EnumFontValue?,
	FontFace: FontValue?,
	LineHeight: NumberValue?,
	MaxVisibleGraphemes: NumberValue?,
	OpenTypeFeatures: StringValue?,
	RichText: BooleanValue?,
	Text: StringValue?,
	TextColor3: Color3Value?,
	TextDirection: EnumTextDirectionValue?,
	TextScaled: BooleanValue?,
	TextSize: NumberValue?,
	TextStrokeColor3: Color3Value?,
	TextStrokeTransparency: NumberValue?,
	TextTransparency: NumberValue?,
	TextTruncate: EnumTextTruncateValue?,
	TextWrapped: BooleanValue?,
	TextXAlignment: EnumTextXAlignmentValue?,
	TextYAlignment: EnumTextYAlignmentValue?,
}
export type TextLabelNativeProps = TextLabelProperties & { [number]: Compose.Child }
export type TextLabelProps = TextLabelNativeProps & { ref: ((TextLabel) -> ())? }

export type UIBaseProperties = InstanceProperties & {}
export type UIBaseNativeProps = UIBaseProperties & { [number]: Compose.Child }
export type UIBaseProps = UIBaseNativeProps & { ref: ((UIBase) -> ())? }

export type UIComponentProperties = UIBaseProperties & {}
export type UIComponentNativeProps = UIComponentProperties & { [number]: Compose.Child }
export type UIComponentProps = UIComponentNativeProps & { ref: ((UIComponent) -> ())? }

export type UIConstraintProperties = UIComponentProperties & {}
export type UIConstraintNativeProps = UIConstraintProperties & { [number]: Compose.Child }
export type UIConstraintProps = UIConstraintNativeProps & { ref: ((UIConstraint) -> ())? }

export type UIAspectRatioConstraintProperties = UIConstraintProperties & {
	AspectRatio: NumberValue?,
	AspectType: EnumAspectTypeValue?,
	DominantAxis: EnumDominantAxisValue?,
}
export type UIAspectRatioConstraintNativeProps = UIAspectRatioConstraintProperties & { [number]: Compose.Child }
export type UIAspectRatioConstraintProps =
	UIAspectRatioConstraintNativeProps
	& { ref: ((UIAspectRatioConstraint) -> ())? }

export type UICornerProperties = UIComponentProperties & {
	BottomLeftRadius: UDimValue?,
	BottomRightRadius: UDimValue?,
	CornerRadius: UDimValue?,
	TopLeftRadius: UDimValue?,
	TopRightRadius: UDimValue?,
}
export type UICornerNativeProps = UICornerProperties & { [number]: Compose.Child }
export type UICornerProps = UICornerNativeProps & { ref: ((UICorner) -> ())? }

export type UIDragDetectorProperties = UIComponentProperties & {
	ActivatedCursorIcon: StringValue?,
	ActivatedCursorIconContent: ContentValue?,
	BoundingBehavior: EnumUIDragDetectorBoundingBehaviorValue?,
	BoundingUI: (GuiBase2dValue | StaticValue)?,
	CursorIcon: StringValue?,
	CursorIconContent: ContentValue?,
	DragAxis: Vector2Value?,
	DragContinue: ((Vector2) -> ())?,
	DragEnd: ((Vector2) -> ())?,
	DragRelativity: EnumUIDragDetectorDragRelativityValue?,
	DragRotation: NumberValue?,
	DragSpace: EnumUIDragDetectorDragSpaceValue?,
	DragStart: ((Vector2) -> ())?,
	DragStyle: EnumUIDragDetectorDragStyleValue?,
	DragUDim2: UDim2Value?,
	Enabled: BooleanValue?,
	MaxDragAngle: NumberValue?,
	MaxDragTranslation: UDim2Value?,
	MinDragAngle: NumberValue?,
	MinDragTranslation: UDim2Value?,
	ReferenceUIInstance: (GuiObjectValue | StaticValue)?,
	ResponseStyle: EnumUIDragDetectorResponseStyleValue?,
	SelectionModeDragSpeed: UDim2Value?,
	SelectionModeRotateSpeed: NumberValue?,
	UIDragSpeedAxisMapping: EnumUIDragSpeedAxisMappingValue?,
}
export type UIDragDetectorNativeProps = UIDragDetectorProperties & { [number]: Compose.Child }
export type UIDragDetectorProps = UIDragDetectorNativeProps & { ref: ((UIDragDetector) -> ())? }

export type UIFlexItemProperties = UIComponentProperties & {
	FlexMode: EnumUIFlexModeValue?,
	GrowRatio: NumberValue?,
	ItemLineAlignment: EnumItemLineAlignmentValue?,
	ShrinkRatio: NumberValue?,
}
export type UIFlexItemNativeProps = UIFlexItemProperties & { [number]: Compose.Child }
export type UIFlexItemProps = UIFlexItemNativeProps & { ref: ((UIFlexItem) -> ())? }

export type UIGradientProperties = UIComponentProperties & {
	Color: ColorSequenceValue?,
	Enabled: BooleanValue?,
	Offset: Vector2Value?,
	Rotation: NumberValue?,
	Scale: NumberValue?,
	TileMode: EnumGradientTileModeValue?,
	Transparency: NumberSequenceValue?,
	Type: EnumGradientTypeValue?,
}
export type UIGradientNativeProps = UIGradientProperties & { [number]: Compose.Child }
export type UIGradientProps = UIGradientNativeProps & { ref: ((UIGradient) -> ())? }

export type UILayoutProperties = UIComponentProperties & {}
export type UILayoutNativeProps = UILayoutProperties & { [number]: Compose.Child }
export type UILayoutProps = UILayoutNativeProps & { ref: ((UILayout) -> ())? }

export type UIGridStyleLayoutProperties = UILayoutProperties & {
	FillDirection: EnumFillDirectionValue?,
	HorizontalAlignment: EnumHorizontalAlignmentValue?,
	SortOrder: EnumSortOrderValue?,
	VerticalAlignment: EnumVerticalAlignmentValue?,
}
export type UIGridStyleLayoutNativeProps = UIGridStyleLayoutProperties & { [number]: Compose.Child }
export type UIGridStyleLayoutProps = UIGridStyleLayoutNativeProps & { ref: ((UIGridStyleLayout) -> ())? }

export type UIListLayoutProperties = UIGridStyleLayoutProperties & {
	HorizontalFlex: EnumUIFlexAlignmentValue?,
	ItemLineAlignment: EnumItemLineAlignmentValue?,
	Padding: UDimValue?,
	VerticalFlex: EnumUIFlexAlignmentValue?,
	Wraps: BooleanValue?,
}
export type UIListLayoutNativeProps = UIListLayoutProperties & { [number]: Compose.Child }
export type UIListLayoutProps = UIListLayoutNativeProps & { ref: ((UIListLayout) -> ())? }

export type UIPaddingProperties = UIComponentProperties & {
	PaddingBottom: UDimValue?,
	PaddingLeft: UDimValue?,
	PaddingRight: UDimValue?,
	PaddingTop: UDimValue?,
}
export type UIPaddingNativeProps = UIPaddingProperties & { [number]: Compose.Child }
export type UIPaddingProps = UIPaddingNativeProps & { ref: ((UIPadding) -> ())? }

export type UIPageLayoutProperties = UIGridStyleLayoutProperties & {
	Animated: BooleanValue?,
	Circular: BooleanValue?,
	EasingDirection: EnumEasingDirectionValue?,
	EasingStyle: EnumEasingStyleValue?,
	GamepadInputEnabled: BooleanValue?,
	Padding: UDimValue?,
	PageEnter: ((Instance) -> ())?,
	PageLeave: ((Instance) -> ())?,
	ScrollWheelInputEnabled: BooleanValue?,
	Stopped: ((Instance) -> ())?,
	TouchInputEnabled: BooleanValue?,
	TweenTime: NumberValue?,
}
export type UIPageLayoutNativeProps = UIPageLayoutProperties & { [number]: Compose.Child }
export type UIPageLayoutProps = UIPageLayoutNativeProps & { ref: ((UIPageLayout) -> ())? }

export type UIScaleProperties = UIComponentProperties & {
	Scale: NumberValue?,
}
export type UIScaleNativeProps = UIScaleProperties & { [number]: Compose.Child }
export type UIScaleProps = UIScaleNativeProps & { ref: ((UIScale) -> ())? }

export type UIShadowProperties = UIComponentProperties & {
	BlurRadius: UDimValue?,
	Color: Color3Value?,
	Enabled: BooleanValue?,
	Offset: UDim2Value?,
	Spread: UDim2Value?,
	Transparency: NumberValue?,
	ZIndex: NumberValue?,
}
export type UIShadowNativeProps = UIShadowProperties & { [number]: Compose.Child }
export type UIShadowProps = UIShadowNativeProps & { ref: ((UIShadow) -> ())? }

export type UISizeConstraintProperties = UIConstraintProperties & {
	MaxSize: Vector2Value?,
	MinSize: Vector2Value?,
}
export type UISizeConstraintNativeProps = UISizeConstraintProperties & { [number]: Compose.Child }
export type UISizeConstraintProps = UISizeConstraintNativeProps & { ref: ((UISizeConstraint) -> ())? }

export type UIStrokeProperties = UIComponentProperties & {
	ApplyStrokeMode: EnumApplyStrokeModeValue?,
	BorderOffset: UDimValue?,
	BorderStrokePosition: EnumBorderStrokePositionValue?,
	Color: Color3Value?,
	Enabled: BooleanValue?,
	LineJoinMode: EnumLineJoinModeValue?,
	StrokeSizingMode: EnumStrokeSizingModeValue?,
	Thickness: NumberValue?,
	Transparency: NumberValue?,
	ZIndex: NumberValue?,
}
export type UIStrokeNativeProps = UIStrokeProperties & { [number]: Compose.Child }
export type UIStrokeProps = UIStrokeNativeProps & { ref: ((UIStroke) -> ())? }

export type ViewportFrameProperties = GuiObjectProperties & {
	Ambient: Color3Value?,
	CurrentCamera: (CameraValue | StaticValue)?,
	ImageColor3: Color3Value?,
	ImageTransparency: NumberValue?,
	LightColor: Color3Value?,
	LightDirection: Vector3Value?,
}
export type ViewportFrameNativeProps = ViewportFrameProperties & { [number]: Compose.Child }
export type ViewportFrameProps = ViewportFrameNativeProps & { ref: ((ViewportFrame) -> ())? }

export type ModelProperties = PVInstanceProperties & {
	ModelStreamingMode: EnumModelStreamingModeValue?,
	PrimaryPart: (BasePartOptionalValue | StaticValue)?,
	WorldPivot: CFrameValue?,
}
export type ModelNativeProps = ModelProperties & { [number]: Compose.Child }
export type ModelProps = ModelNativeProps & { ref: ((Model) -> ())? }

export type WorldRootProperties = ModelProperties & {}
export type WorldRootNativeProps = WorldRootProperties & { [number]: Compose.Child }
export type WorldRootProps = WorldRootNativeProps & { ref: ((WorldRoot) -> ())? }

export type WorldModelProperties = WorldRootProperties & {
	UseWorkspaceCollisionGroups: BooleanValue?,
}
export type WorldModelNativeProps = WorldModelProperties & { [number]: Compose.Child }
export type WorldModelProps = WorldModelNativeProps & { ref: ((WorldModel) -> ())? }

export type RobloxTypes = {
	UDim: typeof(UDim),
	UDim2: typeof(UDim2),
	Vector2: typeof(Vector2),
	Vector3: typeof(Vector3),
	Color3: typeof(Color3),
	CFrame: typeof(CFrame),
	Enum: typeof(Enum),
	Font: typeof(Font),
	Rect: typeof(Rect),
	ColorSequence: typeof(ColorSequence),
	ColorSequenceKeypoint: typeof(ColorSequenceKeypoint),
	NumberSequence: typeof(NumberSequence),
	NumberSequenceKeypoint: typeof(NumberSequenceKeypoint),
	NumberRange: typeof(NumberRange),
	Path2DControlPoint: typeof(Path2DControlPoint),
	FloatCurveKey: typeof(FloatCurveKey),
	TweenInfo: typeof(TweenInfo),
}

export type Observe =
	((GuiBase2d, "AbsolutePosition") -> Compose.Cell<Vector2>)
	& ((GuiBase2d, "AbsoluteSize") -> Compose.Cell<Vector2>)
	& ((GuiObject, "GuiState") -> Compose.Cell<Enum.GuiState>)
	& ((GuiObject, "Interactable") -> Compose.Cell<boolean>)
	& ((GuiObject, "Position") -> Compose.Cell<UDim2>)
	& ((GuiObject, "Size") -> Compose.Cell<UDim2>)
	& ((GuiObject, "Visible") -> Compose.Cell<boolean>)
	& ((GuiService, "PreferredTransparency") -> Compose.Cell<number>)
	& ((GuiService, "ReducedMotionEnabled") -> Compose.Cell<boolean>)
	& ((GuiService, "SelectedObject") -> Compose.Cell<GuiObject?>)
	& ((InputAction, "DisplayName") -> Compose.Cell<string>)
	& ((InputAction, "Enabled") -> Compose.Cell<boolean>)
	& ((InputAction, "PreferredBinding") -> Compose.Cell<InputBinding>)
	& ((InputBinding, "DisplayImage") -> Compose.Cell<Content>)
	& ((InputBinding, "DisplayName") -> Compose.Cell<string>)
	& ((InputBinding, "KeyCode") -> Compose.Cell<Enum.KeyCode>)
	& ((InputBinding, "PrimaryModifier") -> Compose.Cell<Enum.KeyCode>)
	& ((InputBinding, "SecondaryModifier") -> Compose.Cell<Enum.KeyCode>)
	& ((InputContext, "Enabled") -> Compose.Cell<boolean>)
	& ((Instance, "Parent") -> Compose.Cell<Instance?>)
	& ((LayerCollector, "Enabled") -> Compose.Cell<boolean>)
	& ((ScrollingFrame, "AbsoluteWindowSize") -> Compose.Cell<Vector2>)
	& ((ScrollingFrame, "CanvasPosition") -> Compose.Cell<Vector2>)
	& ((TextBox, "FontFace") -> Compose.Cell<Font>)
	& ((TextBox, "LineHeight") -> Compose.Cell<number>)
	& ((TextBox, "RichText") -> Compose.Cell<boolean>)
	& ((TextBox, "Text") -> Compose.Cell<string>)
	& ((TextBox, "TextBounds") -> Compose.Cell<Vector2>)
	& ((TextBox, "TextColor3") -> Compose.Cell<Color3>)
	& ((TextBox, "TextFits") -> Compose.Cell<boolean>)
	& ((TextBox, "TextScaled") -> Compose.Cell<boolean>)
	& ((TextBox, "TextSize") -> Compose.Cell<number>)
	& ((TextBox, "TextTruncate") -> Compose.Cell<Enum.TextTruncate>)
	& ((TextBox, "TextWrapped") -> Compose.Cell<boolean>)
	& ((TextBox, "TextXAlignment") -> Compose.Cell<Enum.TextXAlignment>)
	& ((TextBox, "TextYAlignment") -> Compose.Cell<Enum.TextYAlignment>)
	& ((TextButton, "FontFace") -> Compose.Cell<Font>)
	& ((TextButton, "LineHeight") -> Compose.Cell<number>)
	& ((TextButton, "RichText") -> Compose.Cell<boolean>)
	& ((TextButton, "Text") -> Compose.Cell<string>)
	& ((TextButton, "TextBounds") -> Compose.Cell<Vector2>)
	& ((TextButton, "TextColor3") -> Compose.Cell<Color3>)
	& ((TextButton, "TextFits") -> Compose.Cell<boolean>)
	& ((TextButton, "TextScaled") -> Compose.Cell<boolean>)
	& ((TextButton, "TextSize") -> Compose.Cell<number>)
	& ((TextButton, "TextTruncate") -> Compose.Cell<Enum.TextTruncate>)
	& ((TextButton, "TextWrapped") -> Compose.Cell<boolean>)
	& ((TextButton, "TextXAlignment") -> Compose.Cell<Enum.TextXAlignment>)
	& ((TextButton, "TextYAlignment") -> Compose.Cell<Enum.TextYAlignment>)
	& ((TextLabel, "FontFace") -> Compose.Cell<Font>)
	& ((TextLabel, "LineHeight") -> Compose.Cell<number>)
	& ((TextLabel, "RichText") -> Compose.Cell<boolean>)
	& ((TextLabel, "Text") -> Compose.Cell<string>)
	& ((TextLabel, "TextBounds") -> Compose.Cell<Vector2>)
	& ((TextLabel, "TextColor3") -> Compose.Cell<Color3>)
	& ((TextLabel, "TextFits") -> Compose.Cell<boolean>)
	& ((TextLabel, "TextScaled") -> Compose.Cell<boolean>)
	& ((TextLabel, "TextSize") -> Compose.Cell<number>)
	& ((TextLabel, "TextTruncate") -> Compose.Cell<Enum.TextTruncate>)
	& ((TextLabel, "TextWrapped") -> Compose.Cell<boolean>)
	& ((TextLabel, "TextXAlignment") -> Compose.Cell<Enum.TextXAlignment>)
	& ((TextLabel, "TextYAlignment") -> Compose.Cell<Enum.TextYAlignment>)
	& ((UIGridStyleLayout, "AbsoluteContentSize") -> Compose.Cell<Vector2>)
	& ((UIPageLayout, "CurrentPage") -> Compose.Cell<GuiObject>)
	& ((UserInputService, "GamepadEnabled") -> Compose.Cell<boolean>)
	& ((UserInputService, "KeyboardEnabled") -> Compose.Cell<boolean>)
	& ((UserInputService, "MouseEnabled") -> Compose.Cell<boolean>)
	& ((UserInputService, "PreferredInput") -> Compose.Cell<Enum.PreferredInput>)
	& ((UserInputService, "TouchEnabled") -> Compose.Cell<boolean>)

export type Host = {
	BillboardGui: Constructor<BillboardGuiNativeProps, BillboardGui>,
	Camera: Constructor<CameraNativeProps, Camera>,
	CanvasGroup: Constructor<CanvasGroupNativeProps, CanvasGroup>,
	Folder: Constructor<FolderNativeProps, Folder>,
	Frame: Constructor<FrameNativeProps, Frame>,
	ImageButton: Constructor<ImageButtonNativeProps, ImageButton>,
	ImageLabel: Constructor<ImageLabelNativeProps, ImageLabel>,
	InputAction: Constructor<InputActionNativeProps, InputAction>,
	InputBinding: Constructor<InputBindingNativeProps, InputBinding>,
	InputContext: Constructor<InputContextNativeProps, InputContext>,
	Path2D: Constructor<Path2DNativeProps, Path2D>,
	ScreenGui: Constructor<ScreenGuiNativeProps, ScreenGui>,
	ScrollingFrame: Constructor<ScrollingFrameNativeProps, ScrollingFrame>,
	StyleRule: Constructor<StyleRuleNativeProps, StyleRule>,
	StyleSheet: Constructor<StyleSheetNativeProps, StyleSheet>,
	SurfaceGui: Constructor<SurfaceGuiNativeProps, SurfaceGui>,
	TextBox: Constructor<TextBoxNativeProps, TextBox>,
	TextButton: Constructor<TextButtonNativeProps, TextButton>,
	TextLabel: Constructor<TextLabelNativeProps, TextLabel>,
	UIAspectRatioConstraint: Constructor<UIAspectRatioConstraintNativeProps, UIAspectRatioConstraint>,
	UICorner: Constructor<UICornerNativeProps, UICorner>,
	UIDragDetector: Constructor<UIDragDetectorNativeProps, UIDragDetector>,
	UIFlexItem: Constructor<UIFlexItemNativeProps, UIFlexItem>,
	UIGradient: Constructor<UIGradientNativeProps, UIGradient>,
	UIListLayout: Constructor<UIListLayoutNativeProps, UIListLayout>,
	UIPadding: Constructor<UIPaddingNativeProps, UIPadding>,
	UIPageLayout: Constructor<UIPageLayoutNativeProps, UIPageLayout>,
	UIScale: Constructor<UIScaleNativeProps, UIScale>,
	UIShadow: Constructor<UIShadowNativeProps, UIShadow>,
	UISizeConstraint: Constructor<UISizeConstraintNativeProps, UISizeConstraint>,
	UIStroke: Constructor<UIStrokeNativeProps, UIStroke>,
	ViewportFrame: Constructor<ViewportFrameNativeProps, ViewportFrame>,
	WorldModel: Constructor<WorldModelNativeProps, WorldModel>,
}

return {}
