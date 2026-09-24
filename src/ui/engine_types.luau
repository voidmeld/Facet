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
export type ValueBasePartOptional = Value<BasePart?>
export type ValueBoolean = Value<boolean>
export type ValueCFrame = Value<CFrame>
export type ValueCamera = Value<Camera>
export type ValueColor3 = Value<Color3>
export type ValueColorSequence = Value<ColorSequence>
export type ValueContent = Value<Content>
export type ValueEnumApplyStrokeMode = Value<Enum.ApplyStrokeMode>
export type ValueEnumAspectType = Value<Enum.AspectType>
export type ValueEnumAutomaticSize = Value<Enum.AutomaticSize>
export type ValueEnumBorderMode = Value<Enum.BorderMode>
export type ValueEnumBorderStrokePosition = Value<Enum.BorderStrokePosition>
export type ValueEnumButtonStyle = Value<Enum.ButtonStyle>
export type ValueEnumCameraType = Value<Enum.CameraType>
export type ValueEnumDominantAxis = Value<Enum.DominantAxis>
export type ValueEnumEasingDirection = Value<Enum.EasingDirection>
export type ValueEnumEasingStyle = Value<Enum.EasingStyle>
export type ValueEnumElasticBehavior = Value<Enum.ElasticBehavior>
export type ValueEnumFieldOfViewMode = Value<Enum.FieldOfViewMode>
export type ValueEnumFillDirection = Value<Enum.FillDirection>
export type ValueEnumFont = Value<Enum.Font>
export type ValueEnumFrameStyle = Value<Enum.FrameStyle>
export type ValueEnumGradientTileMode = Value<Enum.GradientTileMode>
export type ValueEnumGradientType = Value<Enum.GradientType>
export type ValueEnumHorizontalAlignment = Value<Enum.HorizontalAlignment>
export type ValueEnumInputActionType = Value<Enum.InputActionType>
export type ValueEnumInputBindingType = Value<Enum.InputBindingType>
export type ValueEnumInputSink = Value<Enum.InputSink>
export type ValueEnumItemLineAlignment = Value<Enum.ItemLineAlignment>
export type ValueEnumKeyCode = Value<Enum.KeyCode>
export type ValueEnumLineJoinMode = Value<Enum.LineJoinMode>
export type ValueEnumModelStreamingMode = Value<Enum.ModelStreamingMode>
export type ValueEnumNormalId = Value<Enum.NormalId>
export type ValueEnumResamplerMode = Value<Enum.ResamplerMode>
export type ValueEnumSafeAreaCompatibility = Value<Enum.SafeAreaCompatibility>
export type ValueEnumScaleType = Value<Enum.ScaleType>
export type ValueEnumScreenInsets = Value<Enum.ScreenInsets>
export type ValueEnumScrollBarInset = Value<Enum.ScrollBarInset>
export type ValueEnumScrollingDirection = Value<Enum.ScrollingDirection>
export type ValueEnumSelectionBehavior = Value<Enum.SelectionBehavior>
export type ValueEnumSizeConstraint = Value<Enum.SizeConstraint>
export type ValueEnumSortOrder = Value<Enum.SortOrder>
export type ValueEnumStartCorner = Value<Enum.StartCorner>
export type ValueEnumStrokeSizingMode = Value<Enum.StrokeSizingMode>
export type ValueEnumSurfaceGuiSizingMode = Value<Enum.SurfaceGuiSizingMode>
export type ValueEnumTextDirection = Value<Enum.TextDirection>
export type ValueEnumTextTruncate = Value<Enum.TextTruncate>
export type ValueEnumTextXAlignment = Value<Enum.TextXAlignment>
export type ValueEnumTextYAlignment = Value<Enum.TextYAlignment>
export type ValueEnumUIDragDetectorBoundingBehavior = Value<Enum.UIDragDetectorBoundingBehavior>
export type ValueEnumUIDragDetectorDragRelativity = Value<Enum.UIDragDetectorDragRelativity>
export type ValueEnumUIDragDetectorDragSpace = Value<Enum.UIDragDetectorDragSpace>
export type ValueEnumUIDragDetectorDragStyle = Value<Enum.UIDragDetectorDragStyle>
export type ValueEnumUIDragDetectorResponseStyle = Value<Enum.UIDragDetectorResponseStyle>
export type ValueEnumUIDragSpeedAxisMapping = Value<Enum.UIDragSpeedAxisMapping>
export type ValueEnumUIFlexAlignment = Value<Enum.UIFlexAlignment>
export type ValueEnumUIFlexMode = Value<Enum.UIFlexMode>
export type ValueEnumVerticalAlignment = Value<Enum.VerticalAlignment>
export type ValueEnumVerticalScrollBarPosition = Value<Enum.VerticalScrollBarPosition>
export type ValueEnumZIndexBehavior = Value<Enum.ZIndexBehavior>
export type ValueFont = Value<Font>
export type ValueGuiBase2d = Value<GuiBase2d>
export type ValueGuiButton = Value<GuiButton>
export type ValueGuiObject = Value<GuiObject>
export type ValueHapticEffect = Value<HapticEffect>
export type ValueHumanoidBasePartNil = Value<Humanoid | BasePart | nil>
export type ValueInstance = Value<Instance>
export type ValueInstanceOptional = Value<Instance?>
export type ValueLocalizationTable = Value<LocalizationTable>
export type ValueNumber = Value<number>
export type ValueNumberSequence = Value<NumberSequence>
export type ValueRect = Value<Rect>
export type ValueSecurityCapabilities = Value<SecurityCapabilities>
export type ValueString = Value<string>
export type ValueUDim = Value<UDim>
export type ValueUDim2 = Value<UDim2>
export type ValueVector2 = Value<Vector2>
export type ValueVector3 = Value<Vector3>

export type ObjectProperties = {
	Changed: ((string) -> ())?,
}
export type ObjectNativeProps = ObjectProperties & { [number]: Compose.Child }
export type ObjectProps = ObjectNativeProps & { ref: ((Object) -> ())? }

export type InstanceProperties = ObjectProperties & {
	Attributes: Attributes?,
	AncestryChanged: ((Instance, Instance?) -> ())?,
	Archivable: ValueBoolean?,
	AttributeChanged: ((string) -> ())?,
	Capabilities: ValueSecurityCapabilities?,
	ChildAdded: ((Instance) -> ())?,
	ChildRemoved: ((Instance) -> ())?,
	DescendantAdded: ((Instance) -> ())?,
	DescendantRemoving: ((Instance) -> ())?,
	Destroying: (() -> ())?,
	Name: ValueString?,
	Parent: (ValueInstanceOptional | StaticValue)?,
	Sandboxed: ValueBoolean?,
	StyledPropertiesChanged: (() -> ())?,
}
export type InstanceNativeProps = InstanceProperties & { [number]: Compose.Child }
export type InstanceProps = InstanceNativeProps & { ref: ((Instance) -> ())? }

export type GuiBaseProperties = InstanceProperties & {}
export type GuiBaseNativeProps = GuiBaseProperties & { [number]: Compose.Child }
export type GuiBaseProps = GuiBaseNativeProps & { ref: ((GuiBase) -> ())? }

export type GuiBase2dProperties = GuiBaseProperties & {
	AutoLocalize: ValueBoolean?,
	RootLocalizationTable: (ValueLocalizationTable | StaticValue)?,
	SelectionBehaviorDown: ValueEnumSelectionBehavior?,
	SelectionBehaviorLeft: ValueEnumSelectionBehavior?,
	SelectionBehaviorRight: ValueEnumSelectionBehavior?,
	SelectionBehaviorUp: ValueEnumSelectionBehavior?,
	SelectionChanged: ((boolean, GuiObject, GuiObject) -> ())?,
	SelectionGroup: ValueBoolean?,
}
export type GuiBase2dNativeProps = GuiBase2dProperties & { [number]: Compose.Child }
export type GuiBase2dProps = GuiBase2dNativeProps & { ref: ((GuiBase2d) -> ())? }

export type LayerCollectorProperties = GuiBase2dProperties & {
	Enabled: ValueBoolean?,
	ResetOnSpawn: ValueBoolean?,
	ZIndexBehavior: ValueEnumZIndexBehavior?,
}
export type LayerCollectorNativeProps = LayerCollectorProperties & { [number]: Compose.Child }
export type LayerCollectorProps = LayerCollectorNativeProps & { ref: ((LayerCollector) -> ())? }

export type BillboardGuiProperties = LayerCollectorProperties & {
	Active: ValueBoolean?,
	Adornee: (ValueInstance | StaticValue)?,
	AlwaysOnTop: ValueBoolean?,
	Brightness: ValueNumber?,
	ClipsDescendants: ValueBoolean?,
	DistanceStep: ValueNumber?,
	ExtentsOffset: ValueVector3?,
	ExtentsOffsetWorldSpace: ValueVector3?,
	LightInfluence: ValueNumber?,
	MaxDistance: ValueNumber?,
	PlayerToHideFrom: (ValueInstance | StaticValue)?,
	Size: ValueUDim2?,
	SizeOffset: ValueVector2?,
	StudsOffset: ValueVector3?,
	StudsOffsetWorldSpace: ValueVector3?,
}
export type BillboardGuiNativeProps = BillboardGuiProperties & { [number]: Compose.Child }
export type BillboardGuiProps = BillboardGuiNativeProps & { ref: ((BillboardGui) -> ())? }

export type PVInstanceProperties = InstanceProperties & {}
export type PVInstanceNativeProps = PVInstanceProperties & { [number]: Compose.Child }
export type PVInstanceProps = PVInstanceNativeProps & { ref: ((PVInstance) -> ())? }

export type CameraProperties = PVInstanceProperties & {
	CFrame: ValueCFrame?,
	CameraSubject: (ValueHumanoidBasePartNil | StaticValue)?,
	CameraType: ValueEnumCameraType?,
	DiagonalFieldOfView: ValueNumber?,
	FieldOfView: ValueNumber?,
	FieldOfViewMode: ValueEnumFieldOfViewMode?,
	Focus: ValueCFrame?,
	HeadLocked: ValueBoolean?,
	HeadScale: ValueNumber?,
	InterpolationFinished: (() -> ())?,
	MaxAxisFieldOfView: ValueNumber?,
	VRTiltAndRollEnabled: ValueBoolean?,
}
export type CameraNativeProps = CameraProperties & { [number]: Compose.Child }
export type CameraProps = CameraNativeProps & { ref: ((Camera) -> ())? }

export type GuiObjectProperties = GuiBase2dProperties & {
	Active: ValueBoolean?,
	AnchorPoint: ValueVector2?,
	AutomaticSize: ValueEnumAutomaticSize?,
	BackgroundColor3: ValueColor3?,
	BackgroundTransparency: ValueNumber?,
	BorderColor3: ValueColor3?,
	BorderMode: ValueEnumBorderMode?,
	BorderSizePixel: ValueNumber?,
	ClipsDescendants: ValueBoolean?,
	InputBegan: ((InputObject) -> ())?,
	InputChanged: ((InputObject) -> ())?,
	InputEnded: ((InputObject) -> ())?,
	InputSink: ValueEnumInputSink?,
	Interactable: ValueBoolean?,
	LayoutOrder: ValueNumber?,
	MouseEnter: ((number, number) -> ())?,
	MouseLeave: ((number, number) -> ())?,
	MouseMoved: ((number, number) -> ())?,
	MouseWheelBackward: ((number, number) -> ())?,
	MouseWheelForward: ((number, number) -> ())?,
	NextSelectionDown: (ValueGuiObject | StaticValue)?,
	NextSelectionLeft: (ValueGuiObject | StaticValue)?,
	NextSelectionRight: (ValueGuiObject | StaticValue)?,
	NextSelectionUp: (ValueGuiObject | StaticValue)?,
	Position: ValueUDim2?,
	Rotation: ValueNumber?,
	Selectable: ValueBoolean?,
	SelectionGained: (() -> ())?,
	SelectionImageObject: (ValueGuiObject | StaticValue)?,
	SelectionLost: (() -> ())?,
	SelectionOrder: ValueNumber?,
	Size: ValueUDim2?,
	SizeConstraint: ValueEnumSizeConstraint?,
	TouchLongPress: (({ Vector2 }, Enum.UserInputState) -> ())?,
	TouchPan: (({ Vector2 }, Vector2, Vector2, Enum.UserInputState) -> ())?,
	TouchPinch: (({ Vector2 }, number, number, Enum.UserInputState) -> ())?,
	TouchRotate: (({ Vector2 }, number, number, Enum.UserInputState) -> ())?,
	TouchSwipe: ((Enum.SwipeDirection, number) -> ())?,
	TouchTap: (({ Vector2 }) -> ())?,
	Visible: ValueBoolean?,
	ZIndex: ValueNumber?,
}
export type GuiObjectNativeProps = GuiObjectProperties & { [number]: Compose.Child }
export type GuiObjectProps = GuiObjectNativeProps & { ref: ((GuiObject) -> ())? }

export type CanvasGroupProperties = GuiObjectProperties & {
	GroupColor3: ValueColor3?,
	GroupTransparency: ValueNumber?,
}
export type CanvasGroupNativeProps = CanvasGroupProperties & { [number]: Compose.Child }
export type CanvasGroupProps = CanvasGroupNativeProps & { ref: ((CanvasGroup) -> ())? }

export type FolderProperties = InstanceProperties & {}
export type FolderNativeProps = FolderProperties & { [number]: Compose.Child }
export type FolderProps = FolderNativeProps & { ref: ((Folder) -> ())? }

export type FrameProperties = GuiObjectProperties & {
	Style: ValueEnumFrameStyle?,
}
export type FrameNativeProps = FrameProperties & { [number]: Compose.Child }
export type FrameProps = FrameNativeProps & { ref: ((Frame) -> ())? }

export type GuiButtonProperties = GuiObjectProperties & {
	Activated: ((InputObject, number) -> ())?,
	AutoButtonColor: ValueBoolean?,
	HoverHapticEffect: (ValueHapticEffect | StaticValue)?,
	Modal: ValueBoolean?,
	MouseButton1Click: (() -> ())?,
	MouseButton1Down: ((number, number) -> ())?,
	MouseButton1Up: ((number, number) -> ())?,
	MouseButton2Click: (() -> ())?,
	MouseButton2Down: ((number, number) -> ())?,
	MouseButton2Up: ((number, number) -> ())?,
	PressHapticEffect: (ValueHapticEffect | StaticValue)?,
	SecondaryActivated: ((InputObject) -> ())?,
	Selected: ValueBoolean?,
	Style: ValueEnumButtonStyle?,
}
export type GuiButtonNativeProps = GuiButtonProperties & { [number]: Compose.Child }
export type GuiButtonProps = GuiButtonNativeProps & { ref: ((GuiButton) -> ())? }

export type ImageButtonProperties = GuiButtonProperties & {
	HoverImage: ValueString?,
	HoverImageContent: ValueContent?,
	Image: ValueString?,
	ImageColor3: ValueColor3?,
	ImageContent: ValueContent?,
	ImageRectOffset: ValueVector2?,
	ImageRectSize: ValueVector2?,
	ImageTransparency: ValueNumber?,
	PressedImage: ValueString?,
	PressedImageContent: ValueContent?,
	ResampleMode: ValueEnumResamplerMode?,
	ScaleType: ValueEnumScaleType?,
	SliceCenter: ValueRect?,
	SliceScale: ValueNumber?,
	TileSize: ValueUDim2?,
}
export type ImageButtonNativeProps = ImageButtonProperties & { [number]: Compose.Child }
export type ImageButtonProps = ImageButtonNativeProps & { ref: ((ImageButton) -> ())? }

export type GuiLabelProperties = GuiObjectProperties & {}
export type GuiLabelNativeProps = GuiLabelProperties & { [number]: Compose.Child }
export type GuiLabelProps = GuiLabelNativeProps & { ref: ((GuiLabel) -> ())? }

export type ImageLabelProperties = GuiLabelProperties & {
	Image: ValueString?,
	ImageColor3: ValueColor3?,
	ImageContent: ValueContent?,
	ImageRectOffset: ValueVector2?,
	ImageRectSize: ValueVector2?,
	ImageTransparency: ValueNumber?,
	ResampleMode: ValueEnumResamplerMode?,
	ScaleType: ValueEnumScaleType?,
	SliceCenter: ValueRect?,
	SliceScale: ValueNumber?,
	TileSize: ValueUDim2?,
}
export type ImageLabelNativeProps = ImageLabelProperties & { [number]: Compose.Child }
export type ImageLabelProps = ImageLabelNativeProps & { ref: ((ImageLabel) -> ())? }

export type InputActionProperties = InstanceProperties & {
	Enabled: ValueBoolean?,
	Pressed: (() -> ())?,
	Released: (() -> ())?,
	StateChanged: ((unknown) -> ())?,
	Type: ValueEnumInputActionType?,
}
export type InputActionNativeProps = InputActionProperties & { [number]: Compose.Child }
export type InputActionProps = InputActionNativeProps & { ref: ((InputAction) -> ())? }

export type InputBindingProperties = InstanceProperties & {
	Backward: ValueEnumKeyCode?,
	ClampMagnitudeToOne: ValueBoolean?,
	DisplayImage: ValueContent?,
	DisplayName: ValueString?,
	Down: ValueEnumKeyCode?,
	Forward: ValueEnumKeyCode?,
	KeyCode: ValueEnumKeyCode?,
	Left: ValueEnumKeyCode?,
	PointerIndex: ValueNumber?,
	PressedThreshold: ValueNumber?,
	PrimaryModifier: ValueEnumKeyCode?,
	ReleasedThreshold: ValueNumber?,
	ResponseCurve: ValueNumber?,
	Right: ValueEnumKeyCode?,
	Scale: ValueNumber?,
	SecondaryModifier: ValueEnumKeyCode?,
	Type: ValueEnumInputBindingType?,
	UIButton: (ValueGuiButton | StaticValue)?,
	UIModifier: (ValueGuiButton | StaticValue)?,
	Up: ValueEnumKeyCode?,
	Vector2Scale: ValueVector2?,
	Vector3Scale: ValueVector3?,
}
export type InputBindingNativeProps = InputBindingProperties & { [number]: Compose.Child }
export type InputBindingProps = InputBindingNativeProps & { ref: ((InputBinding) -> ())? }

export type InputContextProperties = InstanceProperties & {
	Enabled: ValueBoolean?,
	Priority: ValueNumber?,
	Sink: ValueBoolean?,
}
export type InputContextNativeProps = InputContextProperties & { [number]: Compose.Child }
export type InputContextProps = InputContextNativeProps & { ref: ((InputContext) -> ())? }

export type Path2DProperties = GuiBaseProperties & {
	Closed: ValueBoolean?,
	Color3: ValueColor3?,
	ControlPointChanged: (() -> ())?,
	Thickness: ValueNumber?,
	Visible: ValueBoolean?,
	ZIndex: ValueNumber?,
}
export type Path2DNativeProps = Path2DProperties & { [number]: Compose.Child }
export type Path2DProps = Path2DNativeProps & { ref: ((Path2D) -> ())? }

export type ScreenGuiProperties = LayerCollectorProperties & {
	ClipToDeviceSafeArea: ValueBoolean?,
	DisplayOrder: ValueNumber?,
	IgnoreGuiInset: ValueBoolean?,
	SafeAreaCompatibility: ValueEnumSafeAreaCompatibility?,
	ScreenInsets: ValueEnumScreenInsets?,
}
export type ScreenGuiNativeProps = ScreenGuiProperties & { [number]: Compose.Child }
export type ScreenGuiProps = ScreenGuiNativeProps & { ref: ((ScreenGui) -> ())? }

export type ScrollingFrameProperties = GuiObjectProperties & {
	AutomaticCanvasSize: ValueEnumAutomaticSize?,
	BottomImage: ValueString?,
	BottomImageContent: ValueContent?,
	CanvasPosition: ValueVector2?,
	CanvasSize: ValueUDim2?,
	ElasticBehavior: ValueEnumElasticBehavior?,
	HorizontalScrollBarInset: ValueEnumScrollBarInset?,
	MidImage: ValueString?,
	MidImageContent: ValueContent?,
	ScrollBarImageColor3: ValueColor3?,
	ScrollBarImageTransparency: ValueNumber?,
	ScrollBarThickness: ValueNumber?,
	ScrollingDirection: ValueEnumScrollingDirection?,
	ScrollingEnabled: ValueBoolean?,
	TopImage: ValueString?,
	TopImageContent: ValueContent?,
	VerticalScrollBarInset: ValueEnumScrollBarInset?,
	VerticalScrollBarPosition: ValueEnumVerticalScrollBarPosition?,
}
export type ScrollingFrameNativeProps = ScrollingFrameProperties & { [number]: Compose.Child }
export type ScrollingFrameProps = ScrollingFrameNativeProps & { ref: ((ScrollingFrame) -> ())? }

export type StyleBaseProperties = InstanceProperties & {
	StyleRulesChanged: (() -> ())?,
}
export type StyleBaseNativeProps = StyleBaseProperties & { [number]: Compose.Child }
export type StyleBaseProps = StyleBaseNativeProps & { ref: ((StyleBase) -> ())? }

export type StyleRuleProperties = StyleBaseProperties & {
	Priority: ValueNumber?,
	Selector: ValueString?,
}
export type StyleRuleNativeProps = StyleRuleProperties & { [number]: Compose.Child }
export type StyleRuleProps = StyleRuleNativeProps & { ref: ((StyleRule) -> ())? }

export type StyleSheetProperties = StyleBaseProperties & {}
export type StyleSheetNativeProps = StyleSheetProperties & { [number]: Compose.Child }
export type StyleSheetProps = StyleSheetNativeProps & { ref: ((StyleSheet) -> ())? }

export type SurfaceGuiBaseProperties = LayerCollectorProperties & {
	Active: ValueBoolean?,
	Adornee: (ValueInstance | StaticValue)?,
	Face: ValueEnumNormalId?,
}
export type SurfaceGuiBaseNativeProps = SurfaceGuiBaseProperties & { [number]: Compose.Child }
export type SurfaceGuiBaseProps = SurfaceGuiBaseNativeProps & { ref: ((SurfaceGuiBase) -> ())? }

export type SurfaceGuiProperties = SurfaceGuiBaseProperties & {
	AlwaysOnTop: ValueBoolean?,
	Brightness: ValueNumber?,
	CanvasSize: ValueVector2?,
	ClipsDescendants: ValueBoolean?,
	LightInfluence: ValueNumber?,
	MaxDistance: ValueNumber?,
	PixelsPerStud: ValueNumber?,
	SizingMode: ValueEnumSurfaceGuiSizingMode?,
	ToolPunchThroughDistance: ValueNumber?,
	ZOffset: ValueNumber?,
}
export type SurfaceGuiNativeProps = SurfaceGuiProperties & { [number]: Compose.Child }
export type SurfaceGuiProps = SurfaceGuiNativeProps & { ref: ((SurfaceGui) -> ())? }

export type TextBoxProperties = GuiObjectProperties & {
	ClearTextOnFocus: ValueBoolean?,
	CursorPosition: ValueNumber?,
	FocusLost: ((boolean, InputObject) -> ())?,
	Focused: (() -> ())?,
	Font: ValueEnumFont?,
	FontFace: ValueFont?,
	LineHeight: ValueNumber?,
	MaxVisibleGraphemes: ValueNumber?,
	MultiLine: ValueBoolean?,
	OpenTypeFeatures: ValueString?,
	PlaceholderColor3: ValueColor3?,
	PlaceholderText: ValueString?,
	ReturnPressedFromOnScreenKeyboard: (() -> ())?,
	RichText: ValueBoolean?,
	SelectionStart: ValueNumber?,
	ShowNativeInput: ValueBoolean?,
	Text: ValueString?,
	TextColor3: ValueColor3?,
	TextDirection: ValueEnumTextDirection?,
	TextEditable: ValueBoolean?,
	TextScaled: ValueBoolean?,
	TextSize: ValueNumber?,
	TextStrokeColor3: ValueColor3?,
	TextStrokeTransparency: ValueNumber?,
	TextTransparency: ValueNumber?,
	TextTruncate: ValueEnumTextTruncate?,
	TextWrapped: ValueBoolean?,
	TextXAlignment: ValueEnumTextXAlignment?,
	TextYAlignment: ValueEnumTextYAlignment?,
}
export type TextBoxNativeProps = TextBoxProperties & { [number]: Compose.Child }
export type TextBoxProps = TextBoxNativeProps & { ref: ((TextBox) -> ())? }

export type TextButtonProperties = GuiButtonProperties & {
	Font: ValueEnumFont?,
	FontFace: ValueFont?,
	LineHeight: ValueNumber?,
	MaxVisibleGraphemes: ValueNumber?,
	OpenTypeFeatures: ValueString?,
	RichText: ValueBoolean?,
	Text: ValueString?,
	TextColor3: ValueColor3?,
	TextDirection: ValueEnumTextDirection?,
	TextScaled: ValueBoolean?,
	TextSize: ValueNumber?,
	TextStrokeColor3: ValueColor3?,
	TextStrokeTransparency: ValueNumber?,
	TextTransparency: ValueNumber?,
	TextTruncate: ValueEnumTextTruncate?,
	TextWrapped: ValueBoolean?,
	TextXAlignment: ValueEnumTextXAlignment?,
	TextYAlignment: ValueEnumTextYAlignment?,
}
export type TextButtonNativeProps = TextButtonProperties & { [number]: Compose.Child }
export type TextButtonProps = TextButtonNativeProps & { ref: ((TextButton) -> ())? }

export type TextLabelProperties = GuiLabelProperties & {
	Font: ValueEnumFont?,
	FontFace: ValueFont?,
	LineHeight: ValueNumber?,
	MaxVisibleGraphemes: ValueNumber?,
	OpenTypeFeatures: ValueString?,
	RichText: ValueBoolean?,
	Text: ValueString?,
	TextColor3: ValueColor3?,
	TextDirection: ValueEnumTextDirection?,
	TextScaled: ValueBoolean?,
	TextSize: ValueNumber?,
	TextStrokeColor3: ValueColor3?,
	TextStrokeTransparency: ValueNumber?,
	TextTransparency: ValueNumber?,
	TextTruncate: ValueEnumTextTruncate?,
	TextWrapped: ValueBoolean?,
	TextXAlignment: ValueEnumTextXAlignment?,
	TextYAlignment: ValueEnumTextYAlignment?,
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
	AspectRatio: ValueNumber?,
	AspectType: ValueEnumAspectType?,
	DominantAxis: ValueEnumDominantAxis?,
}
export type UIAspectRatioConstraintNativeProps = UIAspectRatioConstraintProperties & { [number]: Compose.Child }
export type UIAspectRatioConstraintProps =
	UIAspectRatioConstraintNativeProps
	& { ref: ((UIAspectRatioConstraint) -> ())? }

export type UICornerProperties = UIComponentProperties & {
	BottomLeftRadius: ValueUDim?,
	BottomRightRadius: ValueUDim?,
	CornerRadius: ValueUDim?,
	TopLeftRadius: ValueUDim?,
	TopRightRadius: ValueUDim?,
}
export type UICornerNativeProps = UICornerProperties & { [number]: Compose.Child }
export type UICornerProps = UICornerNativeProps & { ref: ((UICorner) -> ())? }

export type UIDragDetectorProperties = UIComponentProperties & {
	ActivatedCursorIcon: ValueString?,
	ActivatedCursorIconContent: ValueContent?,
	BoundingBehavior: ValueEnumUIDragDetectorBoundingBehavior?,
	BoundingUI: (ValueGuiBase2d | StaticValue)?,
	CursorIcon: ValueString?,
	CursorIconContent: ValueContent?,
	DragAxis: ValueVector2?,
	DragContinue: ((Vector2) -> ())?,
	DragEnd: ((Vector2) -> ())?,
	DragRelativity: ValueEnumUIDragDetectorDragRelativity?,
	DragRotation: ValueNumber?,
	DragSpace: ValueEnumUIDragDetectorDragSpace?,
	DragStart: ((Vector2) -> ())?,
	DragStyle: ValueEnumUIDragDetectorDragStyle?,
	DragUDim2: ValueUDim2?,
	Enabled: ValueBoolean?,
	MaxDragAngle: ValueNumber?,
	MaxDragTranslation: ValueUDim2?,
	MinDragAngle: ValueNumber?,
	MinDragTranslation: ValueUDim2?,
	ReferenceUIInstance: (ValueGuiObject | StaticValue)?,
	ResponseStyle: ValueEnumUIDragDetectorResponseStyle?,
	SelectionModeDragSpeed: ValueUDim2?,
	SelectionModeRotateSpeed: ValueNumber?,
	UIDragSpeedAxisMapping: ValueEnumUIDragSpeedAxisMapping?,
}
export type UIDragDetectorNativeProps = UIDragDetectorProperties & { [number]: Compose.Child }
export type UIDragDetectorProps = UIDragDetectorNativeProps & { ref: ((UIDragDetector) -> ())? }

export type UIFlexItemProperties = UIComponentProperties & {
	FlexMode: ValueEnumUIFlexMode?,
	GrowRatio: ValueNumber?,
	ItemLineAlignment: ValueEnumItemLineAlignment?,
	ShrinkRatio: ValueNumber?,
}
export type UIFlexItemNativeProps = UIFlexItemProperties & { [number]: Compose.Child }
export type UIFlexItemProps = UIFlexItemNativeProps & { ref: ((UIFlexItem) -> ())? }

export type UIGradientProperties = UIComponentProperties & {
	Color: ValueColorSequence?,
	Enabled: ValueBoolean?,
	Offset: ValueVector2?,
	Rotation: ValueNumber?,
	Scale: ValueNumber?,
	TileMode: ValueEnumGradientTileMode?,
	Transparency: ValueNumberSequence?,
	Type: ValueEnumGradientType?,
}
export type UIGradientNativeProps = UIGradientProperties & { [number]: Compose.Child }
export type UIGradientProps = UIGradientNativeProps & { ref: ((UIGradient) -> ())? }

export type UILayoutProperties = UIComponentProperties & {}
export type UILayoutNativeProps = UILayoutProperties & { [number]: Compose.Child }
export type UILayoutProps = UILayoutNativeProps & { ref: ((UILayout) -> ())? }

export type UIGridStyleLayoutProperties = UILayoutProperties & {
	FillDirection: ValueEnumFillDirection?,
	HorizontalAlignment: ValueEnumHorizontalAlignment?,
	SortOrder: ValueEnumSortOrder?,
	VerticalAlignment: ValueEnumVerticalAlignment?,
}
export type UIGridStyleLayoutNativeProps = UIGridStyleLayoutProperties & { [number]: Compose.Child }
export type UIGridStyleLayoutProps = UIGridStyleLayoutNativeProps & { ref: ((UIGridStyleLayout) -> ())? }

export type UIGridLayoutProperties = UIGridStyleLayoutProperties & {
	CellPadding: ValueUDim2?,
	CellSize: ValueUDim2?,
	FillDirectionMaxCells: ValueNumber?,
	StartCorner: ValueEnumStartCorner?,
}
export type UIGridLayoutNativeProps = UIGridLayoutProperties & { [number]: Compose.Child }
export type UIGridLayoutProps = UIGridLayoutNativeProps & { ref: ((UIGridLayout) -> ())? }

export type UIListLayoutProperties = UIGridStyleLayoutProperties & {
	HorizontalFlex: ValueEnumUIFlexAlignment?,
	ItemLineAlignment: ValueEnumItemLineAlignment?,
	Padding: ValueUDim?,
	VerticalFlex: ValueEnumUIFlexAlignment?,
	Wraps: ValueBoolean?,
}
export type UIListLayoutNativeProps = UIListLayoutProperties & { [number]: Compose.Child }
export type UIListLayoutProps = UIListLayoutNativeProps & { ref: ((UIListLayout) -> ())? }

export type UIPaddingProperties = UIComponentProperties & {
	PaddingBottom: ValueUDim?,
	PaddingLeft: ValueUDim?,
	PaddingRight: ValueUDim?,
	PaddingTop: ValueUDim?,
}
export type UIPaddingNativeProps = UIPaddingProperties & { [number]: Compose.Child }
export type UIPaddingProps = UIPaddingNativeProps & { ref: ((UIPadding) -> ())? }

export type UIPageLayoutProperties = UIGridStyleLayoutProperties & {
	Animated: ValueBoolean?,
	Circular: ValueBoolean?,
	EasingDirection: ValueEnumEasingDirection?,
	EasingStyle: ValueEnumEasingStyle?,
	GamepadInputEnabled: ValueBoolean?,
	Padding: ValueUDim?,
	PageEnter: ((Instance) -> ())?,
	PageLeave: ((Instance) -> ())?,
	ScrollWheelInputEnabled: ValueBoolean?,
	Stopped: ((Instance) -> ())?,
	TouchInputEnabled: ValueBoolean?,
	TweenTime: ValueNumber?,
}
export type UIPageLayoutNativeProps = UIPageLayoutProperties & { [number]: Compose.Child }
export type UIPageLayoutProps = UIPageLayoutNativeProps & { ref: ((UIPageLayout) -> ())? }

export type UIScaleProperties = UIComponentProperties & {
	Scale: ValueNumber?,
}
export type UIScaleNativeProps = UIScaleProperties & { [number]: Compose.Child }
export type UIScaleProps = UIScaleNativeProps & { ref: ((UIScale) -> ())? }

export type UIShadowProperties = UIComponentProperties & {
	BlurRadius: ValueUDim?,
	Color: ValueColor3?,
	Enabled: ValueBoolean?,
	Offset: ValueUDim2?,
	Spread: ValueUDim2?,
	Transparency: ValueNumber?,
	ZIndex: ValueNumber?,
}
export type UIShadowNativeProps = UIShadowProperties & { [number]: Compose.Child }
export type UIShadowProps = UIShadowNativeProps & { ref: ((UIShadow) -> ())? }

export type UISizeConstraintProperties = UIConstraintProperties & {
	MaxSize: ValueVector2?,
	MinSize: ValueVector2?,
}
export type UISizeConstraintNativeProps = UISizeConstraintProperties & { [number]: Compose.Child }
export type UISizeConstraintProps = UISizeConstraintNativeProps & { ref: ((UISizeConstraint) -> ())? }

export type UIStrokeProperties = UIComponentProperties & {
	ApplyStrokeMode: ValueEnumApplyStrokeMode?,
	BorderOffset: ValueUDim?,
	BorderStrokePosition: ValueEnumBorderStrokePosition?,
	Color: ValueColor3?,
	Enabled: ValueBoolean?,
	LineJoinMode: ValueEnumLineJoinMode?,
	StrokeSizingMode: ValueEnumStrokeSizingMode?,
	Thickness: ValueNumber?,
	Transparency: ValueNumber?,
	ZIndex: ValueNumber?,
}
export type UIStrokeNativeProps = UIStrokeProperties & { [number]: Compose.Child }
export type UIStrokeProps = UIStrokeNativeProps & { ref: ((UIStroke) -> ())? }

export type ViewportFrameProperties = GuiObjectProperties & {
	Ambient: ValueColor3?,
	CurrentCamera: (ValueCamera | StaticValue)?,
	ImageColor3: ValueColor3?,
	ImageTransparency: ValueNumber?,
	LightColor: ValueColor3?,
	LightDirection: ValueVector3?,
}
export type ViewportFrameNativeProps = ViewportFrameProperties & { [number]: Compose.Child }
export type ViewportFrameProps = ViewportFrameNativeProps & { ref: ((ViewportFrame) -> ())? }

export type ModelProperties = PVInstanceProperties & {
	ModelStreamingMode: ValueEnumModelStreamingMode?,
	PrimaryPart: (ValueBasePartOptional | StaticValue)?,
	WorldPivot: ValueCFrame?,
}
export type ModelNativeProps = ModelProperties & { [number]: Compose.Child }
export type ModelProps = ModelNativeProps & { ref: ((Model) -> ())? }

export type WorldRootProperties = ModelProperties & {}
export type WorldRootNativeProps = WorldRootProperties & { [number]: Compose.Child }
export type WorldRootProps = WorldRootNativeProps & { ref: ((WorldRoot) -> ())? }

export type WorldModelProperties = WorldRootProperties & {
	UseWorkspaceCollisionGroups: ValueBoolean?,
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
	BrickColor: typeof(BrickColor)?,
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
	UIGridLayout: Constructor<UIGridLayoutNativeProps, UIGridLayout>,
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
