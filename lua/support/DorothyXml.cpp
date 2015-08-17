#include "DorothyXml.h"

static void oHandler(const char* begin, const char* end)
{
#define CHECK_CDATA(name) \
	if (strncmp(begin, #name, sizeof(#name) / sizeof(char) - 1) == 0)\
	{\
		CCSAXParser::placeCDataHeader("</"#name">");\
		return;\
	}
	if (begin < end && *(begin-1) != '/')
	{
		CHECK_CDATA(Call)
		CHECK_CDATA(Script)
		CHECK_CDATA(Slot)
	}
}

static bool isVal(const char* value)
{
	if (value && value[0] == '{') return false;
	return true;
}

#if defined(COCOS2D_DEBUG) && COCOS2D_DEBUG > 0
	#define toVal(s,def) (oVal(s,def,element,#s).c_str())
	#define Val(s) (oVal(s,nullptr,element,#s).c_str())
#else
	#define toVal(s,def) (oVal(s,def).c_str())
	#define Val(s) (oVal(s,nullptr).c_str())
#endif

static const char* _toBoolean(const char* str)
{
	if (strcmp(str,"True") == 0) return "true";
	if (strcmp(str,"False") == 0) return "false";
	return str;
}

#define toBoolean(x) (_toBoolean(toVal(x,"False")))
#define toEase(x) (isVal(x) ? string("oEase.")+Val(x) : Val(x))
#define toGroup(x) (isVal(x) ? string("oData.Group")+Val(x) : Val(x))
#define toBlendFunc(x) (isVal(x) ? string("ccBlendFunc.")+toVal(x,"Zero") : Val(x))
#define toOrientation(x) (isVal(x) ? string("CCOrientation.")+toVal(x,"Down") : Val(x))
#define toTextAlign(x) (isVal(x) ? string("CCTextAlign.")+toVal(x,"HLeft") : Val(x))
#define toText(x) (isVal(x) ? string("\"")+Val(x)+"\"" : Val(x))

#define Self_Check(name) \
	if (self.empty()) { self = getUsableName(#name); names.insert(self); }\
	if (firstItem.empty()) firstItem = self;

// Vec2
#define Vec2_Define \
	const char* x = nullptr;\
	const char* y = nullptr;
#define Vec2_Check \
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }
#define Vec2_Handle \
	items.push(string("oVec2(")+toVal(x,"0")+","+toVal(y,"0")+")");

// Object
#define Object_Define \
	string self;\
	bool hasSelf = false;\
	bool ref = false;
#define Object_Check \
	CASE_STR(Name) { hasSelf = true; self = atts[++i]; break; }\
	CASE_STR(Ref) { ref = strcmp(atts[++i],"True") == 0; break; }

// Speed
#define Speed_Define \
	Object_Define\
	const char* rate = nullptr;
#define Speed_Check \
	Object_Check\
	CASE_STR(Rate) { rate = atts[++i]; break; }
#define Speed_Create
#define Speed_Handle \
	oFunc func = {"CCSpeed(", string(",")+toVal(rate,"1")+")"};\
	funcs.push(func);\
	items.push("");
#define Speed_Finish

// Loop
#define Loop_Define \
	Object_Define\
	const char* times = nullptr;
#define Loop_Check \
	Object_Check\
	CASE_STR(Times) { times = atts[++i]; break; }
#define Loop_Create
#define Loop_Handle \
	oFunc func = {(times ? "CCRepeat(" : "CCRepeatForever("), (times ? string(",")+Val(times)+")" : ")")};\
	funcs.push(func);\
	items.push("");
#define Loop_Finish

// Delay
#define Delay_Define \
	Object_Define\
	const char* time = nullptr;
#define Delay_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }
#define Delay_Create
#define Delay_Handle \
	oFunc func = {string("CCDelay(")+toVal(time,"0")+")",""};\
	funcs.push(func);
#define Delay_Finish

// Scale
#define Scale_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* ease = nullptr;
#define Scale_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Ease) { ease = atts[++i]; break; }
#define Scale_Create
#define Scale_Handle \
	oFunc func = {string("oScale(")+toVal(time,"0")+","+Val(x)+","+Val(y)+(ease ? string(",")+toEase(ease) : "")+")",""};\
	funcs.push(func);
#define Scale_Finish

// Move
#define Move_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* ease = nullptr;
#define Move_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Ease) { ease = atts[++i]; break; }
#define Move_Create
#define Move_Handle \
	oFunc func = {string("oPos(")+toVal(time,"0")+","+Val(x)+","+Val(y)+(ease ? string(",")+toEase(ease) : "")+")",""};\
	funcs.push(func);
#define Move_Finish

// Rotate
#define Rotate_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* angle = nullptr;\
	const char* ease = nullptr;
#define Rotate_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Angle) { angle = atts[++i]; break; }\
	CASE_STR(Ease) { ease = atts[++i]; break; }
#define Rotate_Create
#define Rotate_Handle \
	oFunc func = {string("oRotate(")+toVal(time,"0")+","+Val(angle)+(ease ? string(",")+toEase(ease) : "")+")",""};\
	funcs.push(func);
#define Rotate_Finish

// Opacity
#define Opacity_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* alpha = nullptr;\
	const char* ease = nullptr;
#define Opacity_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Alpha) { alpha = atts[++i]; break; }\
	CASE_STR(Ease) { ease = atts[++i]; break; }
#define Opacity_Create
#define Opacity_Handle \
	oFunc func = {string("oOpacity(")+toVal(time,"0")+","+Val(alpha)+(ease ? string(",")+toEase(ease) : "")+")",""};\
	funcs.push(func);
#define Opacity_Finish

// Skew
#define Skew_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* ease = nullptr;
#define Skew_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Ease) { ease = atts[++i]; break; }
#define Skew_Create
#define Skew_Handle \
	oFunc func = {string("oSkew(")+toVal(time,"0")+","+Val(x)+","+Val(y)+(ease ? string(",")+toEase(ease) : "")+")",""};\
	funcs.push(func);
#define Skew_Finish

// Roll
#define Roll_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* angle = nullptr;\
	const char* ease = nullptr;
#define Roll_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Angle) { angle = atts[++i]; break; }\
	CASE_STR(Ease) { ease = atts[++i]; break; }
#define Roll_Create
#define Roll_Handle \
	oFunc func = {string("oRoll(")+toVal(time,"0")+","+Val(angle)+(ease ? string(",")+toEase(ease) : "")+")",""};\
	funcs.push(func);
#define Roll_Finish

// Jump
#define Jump_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* height = nullptr;\
	const char* jumps = nullptr;
#define Jump_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Height) { height = atts[++i]; break; }\
	CASE_STR(Jumps) { jumps = atts[++i]; break; }
#define Jump_Create
#define Jump_Handle \
	oFunc func = {string("CCJumpTo(")+toVal(time,"0")+","+Val(x)+","+Val(y)+","+Val(height)+","+toVal(jumps,"1")+")",""};\
	funcs.push(func);
#define Jump_Finish

// Bezier
#define Bezier_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* firstX = nullptr;\
	const char* firstY = nullptr;\
	const char* secondX = nullptr;\
	const char* secondY = nullptr;
#define Bezier_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(FirstX) { firstX = atts[++i]; break; }\
	CASE_STR(FirstY) { firstY = atts[++i]; break; }\
	CASE_STR(SecondX) { secondX = atts[++i]; break; }\
	CASE_STR(SecondY) { secondY = atts[++i]; break; }
#define Bezier_Create
#define Bezier_Handle \
	oFunc func = {string("CCBezierTo(")+toVal(time,"0")+",oVec2("+Val(x)+","+Val(y)+"),oVec2("+Val(firstX)+","+Val(firstY)+"),oVec2("+Val(secondX)+","+Val(secondY)+"))",""};\
	funcs.push(func);
#define Bezier_Finish

// Blink
#define Blink_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* blinks = nullptr;
#define Blink_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Blinks) { blinks = atts[++i]; break; }
#define Blink_Create
#define Blink_Handle \
	oFunc func = {string("CCBlink(")+toVal(time,"0")+","+toVal(blinks,"1")+")",""};\
	funcs.push(func);
#define Blink_Finish

// Tint
#define Tint_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* color = nullptr;
#define Tint_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Color) { color = atts[++i]; break; }
#define Tint_Create
#define Tint_Handle \
	oFunc func = {string("CCTintTo(")+toVal(time,"0")+","+toVal(color,"0xffffffff")+")",""};\
	funcs.push(func);
#define Tint_Finish

// Show
#define Show_Define \
	Object_Define
#define Show_Check \
	Object_Check
#define Show_Create
#define Show_Handle \
	oFunc func = {"CCShow()",""};\
	funcs.push(func);
#define Show_Finish

// Hide
#define Hide_Define \
	Object_Define
#define Hide_Check \
	Object_Check
#define Hide_Create
#define Hide_Handle \
	oFunc func = {"CCHide()",""};\
	funcs.push(func);
#define Hide_Finish

// Flip
#define Flip_Define \
	Object_Define\
	const char* x = nullptr;\
	const char* y = nullptr;
#define Flip_Check \
	Object_Check\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }
#define Flip_Create
#define Flip_Handle \
	oFunc func;\
	if (x && y) func.begin = string("CCSpawn({CCFlipX(")+Val(x)+"),CCFlipY("+Val(y)+")})";\
	else if (x && !y) func.begin = string("CCFlipX(")+Val(x)+")";\
	else if (!x && y) func.begin = string("CCFlipY(")+Val(y)+")";\
	else func.begin = string("CCSpawn({CCFlipX(")+Val(x)+"),CCFlipY("+Val(y)+")})";\
	funcs.push(func);
#define Flip_Finish

// Call
#define Call_Define \
	Object_Define
#define Call_Check \
	Object_Check
#define Call_Create
#define Call_Handle \
	oFunc func = {"CCCall(",")"};\
	funcs.push(func);
#define Call_Finish

// Orbit
#define Orbit_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* startRadius = nullptr;\
	const char* deltaRadius = nullptr;\
	const char* startAngleZ = nullptr;\
	const char* deltaAngleZ = nullptr;\
	const char* startAngleX = nullptr;\
	const char* deltaAngleX = nullptr;
#define Orbit_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(StartRadius) { startRadius = atts[++i]; break; }\
	CASE_STR(DeltaRadius) { deltaRadius = atts[++i]; break; }\
	CASE_STR(StartAngleZ) { startAngleZ = atts[++i]; break; }\
	CASE_STR(DeltaAngleZ) { deltaAngleZ = atts[++i]; break; }\
	CASE_STR(StartAngleX) { startAngleX = atts[++i]; break; }\
	CASE_STR(DeltaAngleX) { deltaAngleX = atts[++i]; break; }
#define Orbit_Create
#define Orbit_Handle \
	oFunc func = {string("CCOrbitCamera(")+toVal(time,"0")+","+toVal(startRadius,"0")+","+toVal(deltaRadius,"0")+","+toVal(startAngleZ,"0")+","+toVal(deltaAngleZ,"0")+","+toVal(startAngleX,"0")+","+toVal(deltaAngleX,"0")+")",""};\
	funcs.push(func);
#define Orbit_Finish

// CardinalSpline
#define CardinalSpline_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* tension = nullptr;
#define CardinalSpline_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Tension) { tension = atts[++i]; break; }
#define CardinalSpline_Create
#define CardinalSpline_Handle \
	oFunc func = {string("CCCardinalSplineTo(")+toVal(time,"0")+",{",string("},")+toVal(tension,"0")+")"};\
	funcs.push(func);\
	items.push("CardinalSpline");
#define CardinalSpline_Finish

// Grid.FlipX3D
#define Grid_FlipX3D_Define \
	Object_Define\
	const char* time = nullptr;
#define Grid_FlipX3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }
#define Grid_FlipX3D_Create
#define Grid_FlipX3D_Handle \
	oFunc func = {string("CCGrid:flipX3D(")+toVal(time,"0")+")",""};\
	funcs.push(func);
#define Grid_FlipX3D_Finish

// Grid.FlipY3D
#define Grid_FlipY3D_Define \
	Object_Define\
	const char* time = nullptr;
#define Grid_FlipY3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }
#define Grid_FlipY3D_Create
#define Grid_FlipY3D_Handle \
	oFunc func = {string("CCGrid:flipY3D(")+toVal(time,"0")+")",""};\
	funcs.push(func);
#define Grid_FlipY3D_Finish

// Grid.Lens3D
#define Grid_Lens3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* radius = nullptr;
#define Grid_Lens3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Radius) { radius = atts[++i]; break; }
#define Grid_Lens3D_Create
#define Grid_Lens3D_Handle \
	oFunc func = {string("CCGrid:lens3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),oVec2("+toVal(x,"0")+","+toVal(y,"0")+"),"+toVal(radius,"0")+")",""};\
	funcs.push(func);
#define Grid_Lens3D_Finish

// Grid.Liquid
#define Grid_Liquid_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* waves = nullptr;\
	const char* amplitude = nullptr;
#define Grid_Liquid_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Waves) { waves = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }
#define Grid_Liquid_Create
#define Grid_Liquid_Handle \
	oFunc func = {string("CCGrid:liquid(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(waves,"0")+","+toVal(amplitude,"0")+")",""};\
	funcs.push(func);
#define Grid_Liquid_Finish

// Grid.Reuse
#define Grid_Reuse_Define \
	Object_Define\
	const char* times = nullptr;
#define Grid_Reuse_Check \
	Object_Check\
	CASE_STR(Times) { times = atts[++i]; break; }
#define Grid_Reuse_Create
#define Grid_Reuse_Handle \
	oFunc func = {string("CCGrid:reuse(")+toVal(times,"0")+")",""};\
	funcs.push(func);
#define Grid_Reuse_Finish

// Grid.Ripple3D
#define Grid_Ripple3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* radius = nullptr;\
	const char* waves = nullptr;\
	const char* amplitude = nullptr;
#define Grid_Ripple3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Radius) { radius = atts[++i]; break; }\
	CASE_STR(Waves) { waves = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }
#define Grid_Ripple3D_Create
#define Grid_Ripple3D_Handle \
	oFunc func = {string("CCGrid:ripple3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),oVec2("+toVal(x,"0")+","+toVal(y,"0")+"),"+toVal(radius,"0")+","+\
	toVal(waves,"0")+","+toVal(amplitude,"0")+")",""};\
	funcs.push(func);
#define Grid_Ripple3D_Finish

// Grid.Shaky3D
#define Grid_Shaky3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* range = nullptr;\
	const char* shakeZ = nullptr;
#define Grid_Shaky3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Range) { range = atts[++i]; break; }\
	CASE_STR(ShakeZ) { shakeZ = atts[++i]; break; }
#define Grid_Shaky3D_Create
#define Grid_Shaky3D_Handle \
	oFunc func = {string("CCGrid:shaky3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(range,"0")+","+toBoolean(shakeZ)+")",""};\
	funcs.push(func);
#define Grid_Shaky3D_Finish

// Grid.Stop
#define Grid_Stop_Define \
	Object_Define
#define Grid_Stop_Check \
	Object_Check
#define Grid_Stop_Create
#define Grid_Stop_Handle \
	oFunc func = {"CCGrid:stop()",""};\
	funcs.push(func);
#define Grid_Stop_Finish

// Grid.Twirl
#define Grid_Twirl_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* twirls = nullptr;\
	const char* amplitude = nullptr;
#define Grid_Twirl_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Twirls) { twirls = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }
#define Grid_Twirl_Create
#define Grid_Twirl_Handle \
	oFunc func = {string("CCGrid:twirl(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),oVec2("+toVal(x,"0")+","+toVal(y,"0")+"),"+\
	toVal(twirls,"0")+","+toVal(amplitude,"0")+")",""};\
	funcs.push(func);
#define Grid_Twirl_Finish

// Grid.Wave
#define Grid_Wave_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* waves = nullptr;\
	const char* amplitude = nullptr;\
	const char* horizontal = nullptr;\
	const char* vertical = nullptr;
#define Grid_Wave_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Waves) { waves = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }\
	CASE_STR(Horizontal) { horizontal = atts[++i]; break; }\
	CASE_STR(Vertical) { vertical = atts[++i]; break; }
#define Grid_Wave_Create
#define Grid_Wave_Handle \
	oFunc func = {string("CCGrid:waves(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(waves,"0")+","+toVal(amplitude,"0")+","+\
	toBoolean(horizontal)+","+toBoolean(vertical)+")",""};\
	funcs.push(func);
#define Grid_Wave_Finish

// Grid.Wave3D
#define Grid_Wave3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* waves = nullptr;\
	const char* amplitude = nullptr;
#define Grid_Wave3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Waves) { waves = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }
#define Grid_Wave3D_Create
#define Grid_Wave3D_Handle \
	oFunc func = {string("CCGrid:waves3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(waves,"0")+","+toVal(amplitude,"0")+")",""};\
	funcs.push(func);
#define Grid_Wave3D_Finish

// Tile.FadeOut
#define Tile_FadeOut_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* dir = nullptr;
#define Tile_FadeOut_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Dir) { dir = atts[++i]; break; }
#define Tile_FadeOut_Create
#define Tile_FadeOut_Handle \
	oFunc func = {string("CCTile:fadeOut(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toOrientation(dir)+")",""};\
	funcs.push(func);
#define Tile_FadeOut_Finish

// Tile.Jump3D
#define Tile_Jump3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* jumps = nullptr;\
	const char* amplitude = nullptr;
#define Tile_Jump3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Jumps) { jumps = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }
#define Tile_Jump3D_Create
#define Tile_Jump3D_Handle \
	oFunc func = {string("CCTile:jump3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(jumps,"0")+","+toVal(amplitude,"0")+")",""};\
	funcs.push(func);
#define Tile_Jump3D_Finish

// Tile.Shaky3D
#define Tile_Shaky3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* range = nullptr;\
	const char* shakeZ = nullptr;
#define Tile_Shaky3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Range) { range = atts[++i]; break; }\
	CASE_STR(ShakeZ) { shakeZ = atts[++i]; break; }
#define Tile_Shaky3D_Create
#define Tile_Shaky3D_Handle \
	oFunc func = {string("CCTile:shaky3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(range,"0")+","+toBoolean(shakeZ)+")",""};\
	funcs.push(func);
#define Tile_Shaky3D_Finish

// Tile.Shuffle
#define Tile_Shuffle_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;
#define Tile_Shuffle_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }
#define Tile_Shuffle_Create
#define Tile_Shuffle_Handle \
	oFunc func = {string("CCTile:shuffle(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"))",""};\
	funcs.push(func);
#define Tile_Shuffle_Finish

#define Tile_SplitCols_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* columns = nullptr;
#define Tile_SplitCols_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Columns) { columns = atts[++i]; break; }
#define Tile_SplitCols_Create
#define Tile_SplitCols_Handle \
	oFunc func = {string("CCTile:splitCols(")+toVal(time,"0")+","+toVal(columns,"0")+")",""};\
	funcs.push(func);
#define Tile_SplitCols_Finish

// Tile.SplitRows
#define Tile_SplitRows_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* rows = nullptr;
#define Tile_SplitRows_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(Rows) { rows = atts[++i]; break; }
#define Tile_SplitRows_Create
#define Tile_SplitRows_Handle \
	oFunc func = {string("CCTile:splitRows(")+toVal(time,"0")+","+toVal(rows,"0")+")",""};\
	funcs.push(func);
#define Tile_SplitRows_Finish

// Tile.TurnOff
#define Tile_TurnOff_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;
#define Tile_TurnOff_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }
#define Tile_TurnOff_Create
#define Tile_TurnOff_Handle \
	oFunc func = {string("CCTile:turnOff(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"))",""};\
	funcs.push(func);
#define Tile_TurnOff_Finish

// Tile.Waves3D
#define Tile_Waves3D_Define \
	Object_Define\
	const char* time = nullptr;\
	const char* gridX = nullptr;\
	const char* gridY = nullptr;\
	const char* waves = nullptr;\
	const char* amplitude = nullptr;
#define Tile_Waves3D_Check \
	Object_Check\
	CASE_STR(Time) { time = atts[++i]; break; }\
	CASE_STR(GridX) { gridX = atts[++i]; break; }\
	CASE_STR(GridY) { gridY = atts[++i]; break; }\
	CASE_STR(Waves) { waves = atts[++i]; break; }\
	CASE_STR(Amplitude) { amplitude = atts[++i]; break; }
#define Tile_Waves3D_Create
#define Tile_Waves3D_Handle \
	oFunc func = {string("CCTile:waves3D(")+toVal(time,"0")+\
	",CCSize("+toVal(gridX,"0")+","+toVal(gridY,"0")+"),"+\
	toVal(waves,"0")+","+toVal(amplitude,"0")+")",""};\
	funcs.push(func);
#define Tile_Waves3D_Finish

// Sequence
#define Sequence_Define \
	Object_Define
#define Sequence_Check \
	Object_Check
#define Sequence_Create
#define Sequence_Handle \
	items.push("Sequence");
#define Sequence_Finish

// Spawn
#define Spawn_Define \
	Object_Define
#define Spawn_Check \
	Object_Check
#define Spawn_Create
#define Spawn_Handle \
	items.push("Spawn");
#define Spawn_Finish

#define Add_To_Parent \
	if (!elementStack.empty()) {\
		const oItem& parent = elementStack.top();\
		if (!parent.name.empty())\
		{\
			stream << parent.name << ":addChild(" << self;\
			if (zOrder) {\
				stream << ',' << Val(zOrder);\
				if (tag) stream << ',' << Val(tag);\
			}\
			else if (tag) stream << ",0," << Val(tag);\
			stream << ")\n";\
			if (hasSelf && ref)\
			{\
				stream << firstItem << "." << self << " = " << self << "\n";\
			}\
			stream << "\n";\
		}\
		else if (strcmp(parent.type,"Stencil") == 0)\
		{\
			elementStack.pop();\
			if (!elementStack.empty())\
			{\
				const oItem& newParent = elementStack.top();\
				stream << newParent.name << ".stencil = " << self << "\n\n";\
			}\
		}\
	}\
	else stream << "\n";

// Node
#define Node_Define \
	Object_Define\
	const char* width = nullptr;\
	const char* height = nullptr;\
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* z = nullptr;\
	const char* anchorX = nullptr;\
	const char* anchorY = nullptr;\
	const char* passColor = nullptr;\
	const char* passOpacity = nullptr;\
	const char* color = nullptr;\
	const char* opacity = nullptr;\
	const char* angle = nullptr;\
	const char* scaleX = nullptr;\
	const char* scaleY = nullptr;\
	const char* scheduler = nullptr;\
	const char* skewX = nullptr;\
	const char* skewY = nullptr;\
	const char* zOrder = nullptr;\
	const char* tag = nullptr;\
	const char* transformTarget = nullptr;\
	const char* visible = nullptr;
#define Node_Check \
	Object_Check\
	CASE_STR(Width) { width = atts[++i]; break; }\
	CASE_STR(Height) { height = atts[++i]; break; }\
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Z) { z = atts[++i]; break; }\
	CASE_STR(AnchorX) { anchorX = atts[++i]; break; }\
	CASE_STR(AnchorY) { anchorY = atts[++i]; break; }\
	CASE_STR(PassColor) { passColor = atts[++i]; break; }\
	CASE_STR(PassOpacity) { passOpacity = atts[++i]; break; }\
	CASE_STR(Color) { color = atts[++i]; break; }\
	CASE_STR(Opacity) { opacity = atts[++i]; break; }\
	CASE_STR(Angle) { angle = atts[++i]; break; }\
	CASE_STR(ScaleX) { scaleX = atts[++i]; break; }\
	CASE_STR(ScaleY) { scaleY = atts[++i]; break; }\
	CASE_STR(Scheduler) { scheduler = atts[++i]; break; }\
	CASE_STR(SkewX) { skewX = atts[++i]; break; }\
	CASE_STR(SkewY) { skewY = atts[++i]; break; }\
	CASE_STR(ZOrder) { zOrder = atts[++i]; break; }\
	CASE_STR(Tag) { tag = atts[++i]; break; }\
	CASE_STR(TransformTarget) { transformTarget = atts[++i]; break; }\
	CASE_STR(Visible) { visible = atts[++i]; break; }
#define Node_Create \
	stream << "local " << self << " = CCNode()\n";
#define Node_Handle \
	if (anchorX && anchorY) stream << self << ".anchor = oVec2(" << Val(anchorX) << ',' << Val(anchorY) << ")\n";\
	else if (anchorX && !anchorY) stream << self << ".anchor = oVec2(" << Val(anchorX) << ',' << self << ".anchor.y)\n";\
	else if (!anchorX && anchorY) stream << self << ".anchor = oVec2(" << self << ".anchor.x," << Val(anchorY) << ")\n";\
	if (x) stream << self << ".positionX = " << Val(x) << '\n';\
	if (y) stream << self << ".positionY = " << Val(y) << '\n';\
	if (z) stream << self << ".positionZ = " << Val(z) << '\n';\
	if (passColor) stream << self << ".cascadeColor = " << toBoolean(passColor) << '\n';\
	if (passOpacity) stream << self << ".cascadeOpacity = " << toBoolean(passOpacity) << '\n';\
	if (color) stream << self << ".color = ccColor3(" << Val(color) << ")\n";\
	if (opacity) stream << self << ".opacity = " << Val(opacity) << '\n';\
	if (angle) stream << self << ".angle = " << Val(angle) << '\n';\
	if (scaleX) stream << self << ".scaleX = " << Val(scaleX) << '\n';\
	if (scaleY) stream << self << ".scaleY = " << Val(scaleY) << '\n';\
	if (scheduler) stream << self << ".scheduler = " << Val(scheduler) << '\n';\
	if (skewX) stream << self << ".skewX = " << Val(skewX) << '\n';\
	if (skewY) stream << self << ".skewY = " << Val(skewY) << '\n';\
	if (transformTarget) stream << self << ".transformTarget = " << Val(transformTarget) << '\n';\
	if (visible) stream << self << ".visible = " << toBoolean(visible) << '\n';\
	if (width && height) stream << self << ".contentSize = CCSize(" << Val(width) << ',' << Val(height) << ")\n";\
	else if (width && !height) stream << self << ".width = " << Val(width) << '\n';\
	else if (!width && height) stream << self << ".height = " << Val(height) << '\n';
#define Node_Finish \
	Add_To_Parent

// Node3D
#define Node3D_Define \
	Node_Define\
	const char* angleX = nullptr;\
	const char* angleY = nullptr;
#define Node3D_Check \
	Node_Check\
	CASE_STR(AngleX) { angleX = atts[++i]; break; }\
	CASE_STR(AngleY) { angleY = atts[++i]; break; }
#define Node3D_Create \
	stream << "local " << self << " = oNode3D()\n";
#define Node3D_Handle \
	Node_Handle\
	if (angleX) stream << self << ".angleX = " << Val(angleX) << '\n';\
	if (angleY) stream << self << ".angleY = " << Val(angleY) << '\n';
#define Node3D_Finish \
	Add_To_Parent

// Scene
#define Scene_Define \
	Node_Define
#define Scene_Check \
	Node_Check
#define Scene_Create \
	stream << "local " << self << " = CCScene()\n";
#define Scene_Handle \
	Node_Handle
#define Scene_Finish \
	stream << '\n';

// DrawNode
#define DrawNode_Define \
	Node_Define
#define DrawNode_Check \
	Node_Check
#define DrawNode_Create \
	stream << "local " << self << " = CCDrawNode()\n";
#define DrawNode_Handle \
	Node_Handle
#define DrawNode_Finish \
	Add_To_Parent

// DrawNode.Dot
#define Dot_Define \
	const char* x = nullptr;\
	const char* y = nullptr;\
	const char* radius = nullptr;\
	const char* color = nullptr;
#define Dot_Check \
	CASE_STR(X) { x = atts[++i]; break; }\
	CASE_STR(Y) { y = atts[++i]; break; }\
	CASE_STR(Radius) { radius = atts[++i]; break; }\
	CASE_STR(Color) { color = atts[++i]; break; }
#define Dot_Finish \
	if (!elementStack.empty())\
	{\
		stream << elementStack.top().name <<\
		":drawDot(oVec2(" << toVal(x,"0") << ',' << toVal(y,"0") << ")," <<\
		toVal(radius,"0.5") << ",ccColor4(" << Val(color) << "))\n\n";\
	}

// DrawNode.Polygon
#define Polygon_Define \
	const char* fillColor = nullptr;\
	const char* borderWidth = nullptr;\
	const char* borderColor = nullptr;
#define Polygon_Check \
	CASE_STR(FillColor) { fillColor = atts[++i]; break; }\
	CASE_STR(BorderWidth) { borderWidth = atts[++i]; break; }\
	CASE_STR(BorderColor) { borderColor = atts[++i]; break; }
#define Polygon_Finish \
	if (!elementStack.empty())\
	{\
		oFunc func = {elementStack.top().name+":drawPolygon({",\
		string("},ccColor4(")+Val(fillColor)+"),"+toVal(borderWidth,"0")+",ccColor4("+toVal(borderColor,"")+"))\n\n"};\
		funcs.push(func);\
		items.push("Polygon");\
	}

// DrawNode.Segment
#define Segment_Define \
	const char* beginX = nullptr;\
	const char* beginY = nullptr;\
	const char* endX = nullptr;\
	const char* endY = nullptr;\
	const char* radius = nullptr;\
	const char* color = nullptr;
#define Segment_Check \
	CASE_STR(BeginX) { beginX = atts[++i]; break; }\
	CASE_STR(BeginY) { beginY = atts[++i]; break; }\
	CASE_STR(EndX) { endX = atts[++i]; break; }\
	CASE_STR(EndY) { endY = atts[++i]; break; }\
	CASE_STR(Radius) { radius = atts[++i]; break; }\
	CASE_STR(Color) { color = atts[++i]; break; }
#define Segment_Finish \
	if (!elementStack.empty())\
	{\
		stream << elementStack.top().name <<\
		":drawSegment(oVec2(" << toVal(beginX,"0") << ',' << toVal(beginY,"0") << "),oVec2(" <<\
		toVal(endX,"0") << ',' << toVal(endY,"0") << ")," << toVal(radius,"0.5") << ",ccColor4(" << toVal(color,"") << "))\n\n";\
	}

// Line
#define Line_Define \
	Node_Define
#define Line_Check \
	Node_Check
#define Line_Create \
	stream << "local " << self << " = oLine()\n";
#define Line_Handle \
	Node_Handle
#define Line_Finish \
	Add_To_Parent\
	oFunc func = {string(self)+":set({","})\n"};\
	funcs.push(func);\
	items.push("Line");

// ClipNode
#define ClipNode_Define \
	Node_Define\
	const char* alphaThreshold = nullptr;\
	const char* inverted = nullptr;
#define ClipNode_Check \
	Node_Check\
	CASE_STR(AlphaThreshold) { alphaThreshold = atts[++i]; break; }\
	CASE_STR(Inverted) { inverted = atts[++i]; break; }
#define ClipNode_Create \
	stream << "local " << self << " = CCClipNode()\n";
#define ClipNode_Handle \
	Node_Handle\
	if (alphaThreshold) stream << self << ".alphaThreshold = " << Val(alphaThreshold) << '\n';\
	if (inverted) stream << self << ".inverted = " << toBoolean(inverted) << '\n';
#define ClipNode_Finish \
	Add_To_Parent

// LabelAtlas
#define LabelAtlas_Define \
	Node_Define\
	const char* text = nullptr;\
	const char* fntFile = nullptr;
#define LabelAtlas_Check \
	Node_Check\
	CASE_STR(Text) { text = atts[++i]; break; }\
	CASE_STR(File) { fntFile = atts[++i]; break; }
#define LabelAtlas_Create \
	stream << "local " << self << " = CCLabelAtlas(";\
	if (text && text[0]) stream << toText(text); else stream << "\"\"";\
	if (fntFile) stream << "," << toText(fntFile);\
	stream << ")\n";
#define LabelAtlas_Handle \
	Node_Handle
#define LabelAtlas_Finish \
	Add_To_Parent

// LabelBMFont
#define LabelBMFont_Define \
	Node_Define\
	const char* text = nullptr;\
	const char* fntFile = nullptr;\
	const char* fontWidth = nullptr;\
	const char* alignment = nullptr;\
	const char* imageOffset = nullptr;
#define LabelBMFont_Check \
	Node_Check\
	CASE_STR(Text) { text = atts[++i]; break; }\
	CASE_STR(File) { fntFile = atts[++i]; break; }\
	CASE_STR(FontWidth) { fontWidth = atts[++i]; break; }\
	CASE_STR(Alignment) { alignment = atts[++i]; break; }\
	CASE_STR(ImageOffset) { imageOffset = atts[++i]; break; }
#define LabelBMFont_Create \
	stream << "local " << self << " = CCLabelBMFont(";\
	if (text && text[0]) stream << toText(text); else stream << "\"\"";\
	if (fntFile) stream << "," << toText(fntFile);\
	else stream << ",";\
	stream << ',' << toVal(fontWidth,"CCLabelBMFont.AutomaticWidth") << "," << toTextAlign(alignment) << ',' << toVal(imageOffset,"oVec2.zero") << ")\n";
#define LabelBMFont_Handle \
	Node_Handle
#define LabelBMFont_Finish \
	Add_To_Parent

// LabelTTF
#define LabelTTF_Define \
	Node_Define\
	const char* text = nullptr;\
	const char* fontName = nullptr;\
	const char* fontSize = nullptr;\
	const char* antiAlias = nullptr;
#define LabelTTF_Check \
	Node_Check\
	CASE_STR(Text) { text = atts[++i]; break; }\
	CASE_STR(FontName) { fontName = atts[++i]; break; }\
	CASE_STR(FontSize) { fontSize = atts[++i]; break; }\
	CASE_STR(AntiAlias) { antiAlias = atts[++i]; break; }
#define LabelTTF_Create \
	stream << "local " << self << " = CCLabelTTF(";\
	if (text && text[0]) stream << toText(text); else stream << "\"\"";\
	stream << ',' << toText(fontName) << ',' << Val(fontSize) << ")\n";
#define LabelTTF_Handle \
	Node_Handle\
	if (antiAlias) stream << self << ".texture.antiAlias = " << toBoolean(antiAlias) << '\n';
#define LabelTTF_Finish \
	Add_To_Parent

// Sprite
#define Sprite_Define \
	Node_Define\
	const char* file = nullptr;\
	const char* flipX = nullptr;\
	const char* flipY = nullptr;\
	const char* blendSrc = nullptr;\
	const char* blendDst = nullptr;
#define Sprite_Check \
	Node_Check\
	CASE_STR(File) { file = atts[++i]; break; }\
	CASE_STR(FlipX) { flipX = atts[++i]; break; }\
	CASE_STR(FlipY) { flipY = atts[++i]; break; }\
	CASE_STR(BlendSrc) { blendSrc = atts[++i]; break; }\
	CASE_STR(BlendDst) { blendDst = atts[++i]; break; }
#define Sprite_Create \
	stream << "local " << self << " = CCSprite(";\
	if (file) stream << toText(file) << ")\n";\
	else stream << ")\n";
#define Sprite_Handle \
	Node_Handle\
	if (flipX) stream << self << ".flipX = " << toBoolean(flipX) << '\n';\
	if (flipY) stream << self << ".flipY = " << toBoolean(flipY) << '\n';\
	if (blendSrc && blendDst) stream << self << ".blendFunc = ccBlendFunc("\
									<< toBlendFunc(blendSrc) << "," << toBlendFunc(blendDst) << ")\n";\
	else if (blendSrc && !blendDst) stream << self << ".blendFunc = ccBlendFunc("\
									<< toBlendFunc(blendSrc) << ',' << self << ".blendFunc.dst)\n";\
	else if (!blendSrc && blendDst) stream << self << ".blendFunc = ccBlendFunc(" << self\
									<< ".blendFunc.src," << toBlendFunc(blendDst) << ")\n";
#define Sprite_Finish \
	Add_To_Parent

// SpriteBatch
#define SpriteBatch_Define \
	Node_Define\
	const char* file = nullptr;
#define SpriteBatch_Check \
	Node_Check\
	CASE_STR(File) { file = atts[++i]; break; }
#define SpriteBatch_Create \
	stream << "local " << self << " = CCSpriteBatchNode(" << toText(file) << ")\n";
#define SpriteBatch_Handle \
	Node_Handle
#define SpriteBatch_Finish \
	Add_To_Parent

// Layer
#define Layer_Define \
	Node_Define\
	const char* accelerometerEnabled = nullptr;\
	const char* keypadEnabled = nullptr;\
	const char* touchEnabled = nullptr;\
	const char* multiTouches = nullptr;\
	const char* touchPriority = nullptr;\
	const char* swallowTouches = nullptr;
#define Layer_Check \
	Node_Check\
	CASE_STR(AccelerometerEnabled) { accelerometerEnabled = atts[++i]; break; }\
	CASE_STR(KeypadEnabled) { keypadEnabled = atts[++i]; break; }\
	CASE_STR(TouchEnabled) { touchEnabled = atts[++i]; break; }\
	CASE_STR(MultiTouches) { multiTouches = atts[++i]; break; }\
	CASE_STR(TouchPriority) { touchPriority = atts[++i]; break; }\
	CASE_STR(SwallowTouches) { swallowTouches = atts[++i]; break; }
#define Layer_Create \
	stream << "local " << self << " = CCLayer()\n";
#define Layer_Handle \
	Node_Handle\
	if (accelerometerEnabled) stream << self << ".accelerometerEnabled = " << toBoolean(accelerometerEnabled) << '\n';\
	if (keypadEnabled) stream << self << ".keypadEnabled = " << toBoolean(keypadEnabled) << '\n';\
	if (multiTouches) stream << self << ".multiTouches = " << toBoolean(multiTouches) << '\n';\
	if (touchPriority) stream << self << ".touchPriority = " << Val(touchPriority) << '\n';\
	if (swallowTouches) stream << self << ".swallowTouches = " << toBoolean(swallowTouches) << '\n';\
	if (touchEnabled) stream << self << ".touchEnabled = " << toBoolean(touchEnabled) << '\n';
#define Layer_Finish \
	Add_To_Parent

// LayerColor
#define LayerColor_Define \
	Layer_Define\
	const char* blendSrc = nullptr;\
	const char* blendDst = nullptr;
#define LayerColor_Check \
	Layer_Check\
	CASE_STR(BlendSrc) { blendSrc = atts[++i]; break; }\
	CASE_STR(BlendDst) { blendDst = atts[++i]; break; }
#define LayerColor_Create \
	stream << "local " << self << " = CCLayerColor(ccColor4(" << toVal(color,"") << "))\n";\
	color = nullptr;
#define LayerColor_Handle \
	Layer_Handle\
	if (blendSrc && blendDst) stream << self << ".blendFunc = ccBlendFunc("\
									<< toBlendFunc(blendSrc) << "," << toBlendFunc(blendDst) << ")\n";\
	else if (blendSrc && !blendDst) stream << self << ".blendFunc = ccBlendFunc("\
									<< toBlendFunc(blendSrc) << ',' << self << ".blendFunc.dst)\n";\
	else if (!blendSrc && blendDst) stream << self << ".blendFunc = ccBlendFunc(" << self\
									<< ".blendFunc.src," << toBlendFunc(blendDst) << ")\n";
#define LayerColor_Finish \
	Add_To_Parent

// LayerGradient
#define LayerGradient_Define \
	LayerColor_Define\
	const char* startColor = nullptr;\
	const char* endColor = nullptr;\
	const char* vectorX = nullptr;\
	const char* vectorY = nullptr;
#define LayerGradient_Check \
	LayerColor_Check\
	CASE_STR(StartColor) { startColor = atts[++i]; break; }\
	CASE_STR(EndColor) { endColor = atts[++i]; break; }\
	CASE_STR(VectorX) { vectorX = atts[++i]; break; }\
	CASE_STR(VectorY) { vectorY = atts[++i]; break; }
#define LayerGradient_Create \
	stream << "local " << self << " = CCLayerGradient(ccColor4(" << toVal(startColor,"0xffffffff") << "),ccColor4(" << toVal(endColor,"0xffffffff") << ")," << "oVec2(" << toVal(vectorX,"0") << ',' << toVal(vectorY,"0.5") << ")\n";
#define LayerGradient_Handle \
	LayerColor_Handle
#define LayerGradient_Finish \
	Add_To_Parent

// Menu
#define Menu_Define \
	Layer_Define\
	const char* enabled = nullptr;
#define Menu_Check \
	Layer_Check\
	CASE_STR(Enabled) { enabled = atts[++i]; break; }
#define Menu_Create \
	stream << "local " << self << " = CCMenu()\n";
#define Menu_Handle \
	Layer_Handle\
	if (enabled) stream << self << ".enabled = " << toBoolean(enabled) << '\n';
#define Menu_Finish \
	Add_To_Parent

// MenuItem
#define MenuItem_Define \
	Node_Define\
	const char* enabled = nullptr;
#define MenuItem_Check \
	Node_Check\
	CASE_STR(Enabled) { enabled = atts[++i]; break; }
#define MenuItem_Create \
	stream << "local " << self << " = CCMenuItem()\n";
#define MenuItem_Handle \
	Node_Handle\
	if (enabled) stream << self << ".enabled = " << toBoolean(enabled) << '\n';
#define MenuItem_Finish \
	Add_To_Parent

// World
#define World_Define \
	Node_Define\
	const char* gravityX = nullptr;\
	const char* gravityY = nullptr;\
	const char* showDebug = nullptr;\
	const char* velocityIter = nullptr;\
	const char* positionIter = nullptr;
#define World_Check \
	Node_Check\
	CASE_STR(GravityX) { gravityX = atts[++i]; break; }\
	CASE_STR(GravityY) { gravityY = atts[++i]; break; }\
	CASE_STR(ShowDebug) { showDebug = atts[++i]; break; }\
	CASE_STR(VelocityIter) { velocityIter = atts[++i]; break; }\
	CASE_STR(PositionIter) { positionIter = atts[++i]; break; }
#define World_Create \
	stream << "local " << self << " = oWorld()\n";
#define World_Handle \
	Node_Handle\
	if (gravityX && gravityY) stream << self << ".gravity = oVec2("\
									<< Val(gravityX) << ',' << Val(gravityY) << ")\n";\
	else if (gravityX && !gravityY) stream << self << ".gravity = oVec2("\
									<< Val(gravityX) << ',' << self << ".gravity.y)\n";\
	else if (!gravityX && gravityY) stream << self << ".gravity = oVec2(" << self\
									<< ".gravity.x," << Val(gravityY) << ")\n";\
	if (showDebug) stream << self << ".showDebug = " << toBoolean(showDebug) << '\n';\
	if (velocityIter || positionIter) stream << self << ":setIterations(" << toVal(velocityIter,"8")\
											<< ',' << toVal(positionIter,"3") << ")\n";
#define World_Finish \
	Add_To_Parent

// PlatformWorld
#define PlatformWorld_Define \
	World_Define
#define PlatformWorld_Check \
	World_Check
#define PlatformWorld_Create \
	stream << "local " << self << " = oPlatformWorld()\n";
#define PlatformWorld_Handle \
	World_Handle
#define PlatformWorld_Finish \
	Add_To_Parent

// World.Contact
#define Contact_Define \
	const char* groupA = nullptr;\
	const char* groupB = nullptr;\
	const char* enabled = nullptr;
#define Contact_Check \
	CASE_STR(GroupA) { groupA = atts[++i]; break; }\
	CASE_STR(GroupB) { groupB = atts[++i]; break; }\
	CASE_STR(Enabled) { enabled = atts[++i]; break; }
#define Contact_Finish \
	if (!elementStack.empty())\
	{\
		stream << elementStack.top().name <<\
		":setShouldContact(" << toGroup(groupA) << ',' << toGroup(groupB) << ',' <<\
		(enabled && enabled[0] ? toBoolean(enabled) : "true") << ")\n";\
	}

// Model
#define Model_Define \
	Node_Define\
	const char* filename = nullptr;\
	const char* look = nullptr;\
	const char* loop = nullptr;\
	const char* play = nullptr;\
	const char* faceRight = nullptr;\
	const char* speed = nullptr;
#define Model_Check \
	Node_Check\
	CASE_STR(File) { filename = atts[++i]; break; }\
	CASE_STR(Look) { look = atts[++i]; break; }\
	CASE_STR(Loop) { loop = atts[++i]; break; }\
	CASE_STR(Play) { play = atts[++i]; break; }\
	CASE_STR(FaceRight) { faceRight = atts[++i]; break; }\
	CASE_STR(Speed) { speed = atts[++i]; break; }
#define Model_Create \
	stream << "local " << self << " = oModel(" << toText(filename) << ")\n";
#define Model_Handle \
	Node_Handle\
	if (look) stream << self << ".look = \"" << Val(look) << "\"\n";\
	if (loop) stream << self << ".loop = " << toBoolean(loop) << '\n';\
	if (play) stream << self << ":play(\"" << Val(play) << "\")\n";\
	if (faceRight) stream << self << ".faceRight = " << toBoolean(faceRight) << '\n';\
	if (speed) stream << self << ".speed = " << Val(speed) << '\n';
#define Model_Finish \
	Add_To_Parent

// Body
#define Body_Define \
	Node_Define\
	const char* file = nullptr;\
	const char* group = nullptr;\
	const char* world = nullptr;
#define Body_Check \
	Node_Check\
	CASE_STR(File) { file = atts[++i]; break; }\
	CASE_STR(Group) { group = atts[++i]; break; }\
	CASE_STR(World) { world = atts[++i]; break; }
#define Body_Create \
	stream << "local " << self << " = oBody(" << toText(file)\
			<< ',' << Val(world) << ",oVec2(" << toVal(x,"0") << ',' << toVal(y,"0") << "),"\
			<< toVal(angle,"0") << ")\n";\
	x = y = angle = nullptr;
#define Body_Handle \
	Node_Handle\
	if (group) stream << self << ".group = " << toGroup(group) << '\n';
#define Body_Finish \
	Add_To_Parent

// ModuleNode
#define ModuleNode_Define \
	Object_Define
#define ModuleNode_Check \
	Object_Check\
	else attributes[__targetStrForSwitch] = atts[++i];
#define ModuleNode_Create \
	stream << "local " << self << " = " << element << "{";
#define ModuleNode_Handle \
	auto it = attributes.begin();\
	while (it != attributes.end())\
	{\
		stream << (char)tolower(it->first[0]) << it->first.substr(1) << " = ";\
		char* p;\
		strtod(it->second.c_str(), &p);\
		if (*p == 0) stream << it->second;\
		else stream << toText(it->second.c_str());\
		++it;\
		if (it != attributes.end())\
		{\
			stream << ", ";\
		}\
	}\
	attributes.clear();\
	stream << "}\n";
#define ModuleNode_Finish \
	if (!elementStack.empty())\
	{\
		const oItem& parent = elementStack.top();\
		if (!parent.name.empty())\
		{\
			stream << parent.name << ":addChild(" << self << ")\n";\
			if (hasSelf && ref)\
			{\
				stream << firstItem << "." << self << " = " << self << "\n";\
			}\
			stream << "\n";\
		}\
		else if (strcmp(parent.type,"Stencil") == 0)\
		{\
			elementStack.pop();\
			if (!elementStack.empty())\
			{\
				const oItem& newParent = elementStack.top();\
				stream << newParent.name << ".stencil = " << self << "\n\n";\
			}\
		}\
	}\
	else stream << "\n";

// Import
#define Import_Define \
	const char* module = nullptr;\
	const char* name = nullptr;
#define Import_Check \
	CASE_STR(Module) { module = atts[++i]; break; }\
	CASE_STR(Name) { name = atts[++i]; break; }
#define Import_Create \
	if (module) {\
		string mod(module);\
		size_t pos = mod.rfind('.');\
		string modStr = (name ? name : (pos == string::npos ? string(module) : mod.substr(pos+1)));\
		imported.insert(modStr);\
		requires << "local " << modStr << " = require(\"" << module << "\")\n";}

// Item
#define NodeItem_Define \
	const char* name = nullptr;
#define NodeItem_Check \
	CASE_STR(Name) { name = atts[++i]; break; }
#define NodeItem_Create \
	stream << "local " << Val(name) << " = " << elementStack.top().name << '.' << Val(name) << "\n\n";\
	if (name && name[0])\
	{\
		oItem item = { "Item", name };\
		elementStack.push(item);\
	}

// Slot
#define Slot_Define \
	const char* name = nullptr;\
	const char* args = nullptr;
#define Slot_Check \
	CASE_STR(Name) { name = atts[++i]; break; }\
	CASE_STR(Args) { args = atts[++i]; break; }
#define Slot_Create \
	oFunc func = {elementStack.top().name+":slots("+toText(name)+",function("+(args ? args : "")+")", "end)"};\
	funcs.push(func);

#define Item_Define(name) name##_Define
#define Item_Loop(name) \
	for (int i = 0; atts[i] != nullptr; i++)\
	{\
		SWITCH_STR_START(atts[i])\
		{\
			name##_Check\
		}\
		SWITCH_STR_END\
	}
#define Item_Create(name) name##_Create
#define Item_Handle(name) name##_Handle
#define Item_Push(name) name##_Finish;oItem item = {#name,self,ref};elementStack.push(item);

#define Item(name,var) \
	CASE_STR(name)\
	{\
		Item_Define(name)\
		Item_Loop(name)\
		Self_Check(var)\
		Item_Create(name)\
		Item_Handle(name)\
		Item_Push(name)\
		break;\
	}

#define CASE_STR_DOT(prename,name) __CASE_STR1(#prename"."#name, prename##name)
#define ItemDot_Push(prename,name) prename##_##name##_Finish;oItem item = {#prename"."#name,self,ref};elementStack.push(item);
#define ItemDot(prename,name,var) \
	CASE_STR_DOT(prename,name)\
	{\
		Item_Define(prename##_##name)\
		Item_Loop(prename##_##name)\
		Self_Check(var)\
		Item_Create(prename##_##name)\
		Item_Handle(prename##_##name)\
		ItemDot_Push(prename,name)\
		break;\
	}

class oXmlDelegate : public CCSAXDelegator
{
public:
	oXmlDelegate(CCSAXParser* parser):
	codes(nullptr),
	parser(parser)
	{ }
	virtual void startElement(void *ctx, const char *name, const char **atts);
	virtual void endElement(void *ctx, const char *name);
	virtual void textHandler(void *ctx, const char *s, int len);
	string oVal(const char* value, const char* def = nullptr, const char* element = nullptr, const char* attr = nullptr);
public:
	void clear()
	{
		codes = nullptr;
		for (; !elementStack.empty(); elementStack.pop());
		for (; !funcs.empty(); funcs.pop());
		for (; !items.empty(); items.pop());
		stream.clear();
		stream.str("");
		requires.clear();
		requires.str("");
		names.clear();
		imported.clear();
		firstItem.clear();
		lastError.clear();
	}
	void begin()
	{
		oXmlDelegate::clear();
		stream <<
		"return function(args)\n"
		"Dorothy(args)\n\n";
	}
	void end()
	{
		stream << "return " << firstItem << "\nend";
	}
	string getResult()
	{
		if (lastError.empty())
		{
			string requireStr = requires.str();
			return requireStr + (requireStr.empty() ? "" : "\n") + stream.str();
		}
		return string();
	}
	const string& getLastError()
	{
		return lastError;
	}
private:
	string getUsableName(const char* baseName)
	{
		char number[7];// max number can only have 6 digits
		int index = 1;
		string base(baseName);
		string name;
		do
		{
			sprintf(number,"%d",index);
			name = base + number;
			auto it = names.find(name);
			if (it == names.end()) break;
			else index++;
		} 
		while (true);
		return name;
	}
private:
	struct oItem
	{
		const char* type;
		string name;
		bool ref;
	};
	struct oFunc
	{
		string begin;
		string end;
	};
	CCSAXParser* parser;
	// Script
	const char* codes;
	// Loader
	string firstItem;
	string lastError;
	stack<oFunc> funcs;
	stack<string> items;
	stack<oItem> elementStack;
	unordered_set<string> names;
	unordered_set<string> imported;
	unordered_map<string, string> attributes;
	ostringstream stream;
	ostringstream requires;
};

string oXmlDelegate::oVal(const char* value, const char* def, const char* element, const char* attr)
{
	if (!value || !value[0])
	{
		if (def) return string(def);
		else if (attr && element)
		{
			char num[10];
			sprintf(num, "%d", parser->getLineNumber(element));
			lastError += string("Missing attribute ") + (char)toupper(attr[0]) + string(attr).substr(1) + " for " + element + ", at line " + num + "\n";
		}
		return string();
	}
	if (value[0] == '{')
	{
		string valStr(value);
		if (valStr.back() != '}') return valStr;
		size_t start = 1;
		for (; valStr[start] == ' ' || valStr[start] == '\t'; ++start);
		size_t end = valStr.size() - 2;
		for (; valStr[end] == ' ' || valStr[end] == '\t'; --end);
		if (end < start)
		{
			if (attr && element)
			{
				char num[10];
				sprintf(num, "%d", parser->getLineNumber(element));
				lastError += string("Missing attribute ") + (char)toupper(attr[0]) + string(attr).substr(1) + " for " + element + ", at line " + num + "\n";
			}
			return string();
		}
		valStr = valStr.substr(start, end - start + 1);
		string newStr;
		start = 0;
		size_t i = 0;
		while (i < valStr.size())
		{
			if (valStr[i] == '$' && i < valStr.size() - 1)
			{
				string parent;
				if (!elementStack.empty())
				{
					oItem top = elementStack.top();
					if (!top.name.empty())
					{
						parent = top.name;
					}
					else if (strcmp(top.type, "Stencil") == 0)
					{
						elementStack.pop();
						if (!elementStack.empty())
						{
							const oItem& newTop = elementStack.top();
							parent = newTop.name;
						}
						elementStack.push(top);
					}
				}
				if (parent.empty() && element)
				{
					char num[10];
					sprintf(num, "%d", parser->getLineNumber(element));
					lastError += string("The $ expression can`t be used in tag at line ") + num + "\n";
				}
				newStr += valStr.substr(start, i - start);
				i++;
				start = i + 1;
				switch (valStr[i])
				{
				case 'L':
					newStr += "0";
					break;
				case 'W':
				case 'R':
					newStr += parent + ".width";
					break;
				case 'H':
				case 'T':
					newStr += parent + ".height";
					break;
				case 'B':
					newStr += "0";
					break;
				case 'X':
					newStr += parent + ".width*0.5";
					break;
				case 'Y':
					newStr += parent + ".height*0.5";
					break;
				default:
					if (element)
					{
						char num[10];
						sprintf(num, "%d", parser->getLineNumber(element));
						lastError += string("Invalid expression $") + valStr[i] + " at line " + num + "\n";
					}
					break;
				}
			}
			i++;
		}
		if (0 < start)
		{
			if (start < valStr.size()) newStr += valStr.substr(start);
			return newStr;
		}
		else return valStr;
	}
	else return string(value);
}

void oXmlDelegate::startElement(void* ctx, const char* element, const char** atts)
{
	SWITCH_STR_START(element)
	{
		Item(Node, node)
		Item(Node3D, node3D)
		Item(Scene, scene)
		Item(DrawNode, drawNode)
		Item(Line, line)
		Item(Sprite, sprite)
		Item(SpriteBatch, spriteBatch)
		Item(Layer, layer)
		Item(LayerColor, layer)
		Item(LayerGradient, layer)
		Item(ClipNode, clipNode)
		Item(LabelAtlas, label)
		Item(LabelBMFont, label)
		Item(LabelTTF, label)
		Item(Menu, menu)
		Item(MenuItem, menuItem)

		Item(World, world)
		Item(PlatformWorld, world)
		Item(Model, model)
		Item(Body, body)

		Item(Speed, speed)

		Item(Delay, delay)
		Item(Scale, scale)
		Item(Move, move)
		Item(Rotate, rotate)
		Item(Opacity, opacity)
		Item(Skew, skew)
		Item(Roll, roll)
		Item(Jump, jump)
		Item(Bezier, bezier)
		Item(Blink, blink)
		Item(Tint, tint)
		Item(Show, show)
		Item(Hide, hide)
		Item(Flip, flip)
		Item(Call, call)
		Item(Orbit, orbit)

		Item(Sequence, sequence)
		Item(Spawn, spawn)
		Item(Loop, loop)
		Item(CardinalSpline, cardinalSpline)

		ItemDot(Grid,FlipX3D, gridFlipX3D)
		ItemDot(Grid,FlipY3D, gridFlipY3D)
		ItemDot(Grid,Lens3D, gridLens3D)
		ItemDot(Grid,Liquid, gridLiquid)
		ItemDot(Grid,Reuse, gridReuse)
		ItemDot(Grid,Ripple3D, gridRipple3D)
		ItemDot(Grid,Shaky3D, gridShaky3D)
		ItemDot(Grid,Stop, gridStop)
		ItemDot(Grid,Twirl, gridTwirl)
		ItemDot(Grid,Wave, gridWave)
		ItemDot(Grid,Wave3D, gridWave3D)

		ItemDot(Tile,FadeOut, tileFadeOut)
		ItemDot(Tile,Jump3D, tileJump3D)
		ItemDot(Tile,Shaky3D, tileShaky3D)
		ItemDot(Tile,Shuffle, tileShuffle)
		ItemDot(Tile,SplitCols, tileSplitCols)
		ItemDot(Tile,SplitRows, tileSplitRows)
		ItemDot(Tile,TurnOff, tileTurnOff)
		ItemDot(Tile,Waves3D, tileWaves3D)

		CASE_STR(Vec2)
		{
			Item_Define(Vec2)
			Item_Loop(Vec2)
			Item_Handle(Vec2)
			break;
		}
		CASE_STR(Dot)
		{
			Item_Define(Dot)
			Item_Loop(Dot)
			Dot_Finish
			break;
		}
		CASE_STR(Polygon)
		{
			Item_Define(Polygon)
			Item_Loop(Polygon)
			Polygon_Finish
			break;
		}
		CASE_STR(Segment)
		{
			Item_Define(Segment)
			Item_Loop(Segment)
			Segment_Finish
			break;
		}
		CASE_STR(Contact)
		{
			Item_Define(Contact)
			Item_Loop(Contact)
			Contact_Finish
			break;
		}
		CASE_STR(Stencil)
		{
			oItem item = { "Stencil" };
			elementStack.push(item);
			break;
		}
		CASE_STR(Import)
		{
			Item_Define(Import)
			Item_Loop(Import)
			Import_Create
			break;
		}
		CASE_STR(Action)
		{
			oItem item = { "Action" };
			elementStack.push(item);
			break;
		}
		CASE_STR(Item)
		{
			Item_Define(NodeItem)
			Item_Loop(NodeItem)
			Item_Create(NodeItem)
			break;
		}
		CASE_STR(Slot)
		{
			Item_Define(Slot)
			Item_Loop(Slot)
			Item_Create(Slot)
			break;
		}
		CASE_STR(Script) break;
		{
			Item_Define(ModuleNode)
			Item_Loop(ModuleNode)
			Self_Check(item)
			Item_Create(ModuleNode)
			Item_Handle(ModuleNode)
			ModuleNode_Finish;
			oItem item = { element, self, ref };
			elementStack.push(item);
		}
	}
	SWITCH_STR_END
}

void oXmlDelegate::endElement(void *ctx, const char *name)
{
	if (elementStack.empty()) return;
	oItem currentData = elementStack.top();
	if (strcmp(name, elementStack.top().type) == 0) elementStack.pop();
	bool parentIsAction = !elementStack.empty() && strcmp(elementStack.top().type, "Action") == 0;

	SWITCH_STR_START(name)
	{
		CASE_STR(Script)
		{
			stream << (codes ? codes : "") << '\n';
			codes = nullptr;
			break;
		}
		CASE_STR(Call)
		{
			oFunc func = funcs.top();
			funcs.pop();
			string tempItem = func.begin + "function()\n" + (codes ? codes : "") + "\nend" + func.end;
			if (parentIsAction)
			{
				stream << "local " << currentData.name << " = " << tempItem << '\n';
			}
			else
			{
				items.push(tempItem);
				auto it = names.find(currentData.name);
				if (it != names.end()) names.erase(it);
			}
			break;
		}
		CASE_STR(Slot)
		{
			oFunc func = funcs.top();
			funcs.pop();
			stream << func.begin << (codes ? codes : "") << func.end << '\n';
			break;
		}
		CASE_STR(Speed) goto FLAG_WRAP_ACTION_BEGIN;
		CASE_STR(Loop) goto FLAG_WRAP_ACTION_BEGIN;
		goto FLAG_WRAP_ACTION_END;
		FLAG_WRAP_ACTION_BEGIN:
		{
			oFunc func = funcs.top();
			funcs.pop();
			string tempItem = func.begin;
			if (items.top() != "")
			{
				tempItem += items.top();
				items.pop();
			}
			items.pop();
			tempItem += func.end;
			if (parentIsAction)
			{
				stream << "local " << currentData.name << " = " << tempItem << '\n';
			}
			else
			{
				items.push(tempItem);
				auto it = names.find(currentData.name);
				if (it != names.end()) names.erase(it);
			}
			break;
		}
		FLAG_WRAP_ACTION_END:
		#define CaseAction(x) CASE_STR(x) goto FLAG_ACTION_BEGIN;
		#define CaseActionDot(x1,x2) CASE_STR_DOT(x1,x2) goto FLAG_ACTION_BEGIN;
		CaseAction(Delay)
		CaseAction(Scale)
		CaseAction(Move)
		CaseAction(Rotate)
		CaseAction(Opacity)
		CaseAction(Skew)
		CaseAction(Roll)
		CaseAction(Jump)
		CaseAction(Bezier)
		CaseAction(Blink)
		CaseAction(Tint)
		CaseAction(Show)
		CaseAction(Hide)
		CaseAction(Flip)
		CaseAction(Orbit)
		CaseActionDot(Grid,FlipX3D)
		CaseActionDot(Grid,FlipY3D)
		CaseActionDot(Grid,Lens3D)
		CaseActionDot(Grid,Liquid)
		CaseActionDot(Grid,Reuse)
		CaseActionDot(Grid,Ripple3D)
		CaseActionDot(Grid,Shaky3D)
		CaseActionDot(Grid,Twirl)
		CaseActionDot(Grid,Stop)
		CaseActionDot(Grid,Wave)
		CaseActionDot(Grid,Wave3D)
		CaseActionDot(Tile,FadeOut)
		CaseActionDot(Tile,Jump3D)
		CaseActionDot(Tile,Shaky3D)
		CaseActionDot(Tile,Shuffle)
		CaseActionDot(Tile,SplitCols)
		CaseActionDot(Tile,SplitRows)
		CaseActionDot(Tile,TurnOff)
		CaseActionDot(Tile,Waves3D)
		goto FLAG_ACTION_END;
		FLAG_ACTION_BEGIN:
		{
			oFunc func = funcs.top();
			funcs.pop();
			if (parentIsAction)
			{
				stream << "local " << currentData.name << " = " << func.begin << '\n';
			}
			else
			{
				items.push(func.begin);
				auto it = names.find(currentData.name);
				if (it != names.end()) names.erase(it);
			}
			break;
		}
		FLAG_ACTION_END:
		CASE_STR(Sequence) goto FLAG_ACTION_GROUP_BEGIN;
		CASE_STR(Spawn) goto FLAG_ACTION_GROUP_BEGIN;
		goto FLAG_ACTION_GROUP_END;
		FLAG_ACTION_GROUP_BEGIN:
		{
			string tempItem = string("CC") + name + "({";
			stack<string> tempStack;
			while (items.top() != name)
			{
				tempStack.push(items.top());
				items.pop();
			}
			items.pop();
			while (!tempStack.empty())
			{
				tempItem += tempStack.top();
				tempStack.pop();
				if (!tempStack.empty()) tempItem += ",";
			}
			tempItem += "})";
			if (parentIsAction)
			{
				stream << "local " << currentData.name << " = " << tempItem << '\n';
			}
			else
			{
				items.push(tempItem);
				auto it = names.find(currentData.name);
				if (it != names.end()) names.erase(it);
			}
			break;
		}
		FLAG_ACTION_GROUP_END:
		CASE_STR(CardinalSpline)
		{
			oFunc func = funcs.top();
			funcs.pop();
			string tempItem = func.begin;
			stack<string> tempStack;
			while (items.top() != name)
			{
				tempStack.push(items.top());
				items.pop();
			}
			items.pop();
			while (!tempStack.empty())
			{
				tempItem += tempStack.top();
				tempStack.pop();
				if (!tempStack.empty()) tempItem += ",";
			}
			tempItem += func.end;
			if (parentIsAction)
			{
				stream << "local " << currentData.name << " = " << tempItem << '\n';
			}
			else
			{
				items.push(tempItem);
				auto it = names.find(currentData.name);
				if (it != names.end()) names.erase(it);
			}
			break;
		}
		CASE_STR(Polygon) goto FLAG_VEC2_CONTAINER_BEGIN;
		CASE_STR(Line) goto FLAG_VEC2_CONTAINER_BEGIN;
		goto FLAG_VEC2_CONTAINER_END;
		FLAG_VEC2_CONTAINER_BEGIN:
		{
			oFunc func = funcs.top();
			funcs.pop();
			stream << func.begin;
			stack<string> tempStack;
			while (items.top() != name)
			{
				tempStack.push(items.top());
				items.pop();
			}
			items.pop();
			while (!tempStack.empty())
			{
				stream << tempStack.top();
				tempStack.pop();
				if (!tempStack.empty()) stream << ',';
			}
			stream << func.end;
			break;
		}
		FLAG_VEC2_CONTAINER_END:
		CASE_STR(Action)
		{
			stream << "\n";
			break;
		}
		#define CaseBuiltin(x) CASE_STR(x) goto FLAG_OTHER_BUILTIN_BEGIN;
		CaseBuiltin(Node)
		CaseBuiltin(Node3D)
		CaseBuiltin(Scene)
		CaseBuiltin(DrawNode)
		CaseBuiltin(Sprite)
		CaseBuiltin(SpriteBatch)
		CaseBuiltin(Layer)
		CaseBuiltin(LayerColor)
		CaseBuiltin(LayerGradient)
		CaseBuiltin(ClipNode)
		CaseBuiltin(LabelAtlas)
		CaseBuiltin(LabelBMFont)
		CaseBuiltin(LabelTTF)
		CaseBuiltin(Menu)
		CaseBuiltin(MenuItem)
		CaseBuiltin(World)
		CaseBuiltin(PlatformWorld)
		CaseBuiltin(Model)
		CaseBuiltin(Body)
		CaseBuiltin(Vec2)
		CaseBuiltin(Dot)
		CaseBuiltin(Segment)
		CaseBuiltin(Contact)
		CaseBuiltin(Stencil)
		CaseBuiltin(Import)
		CaseBuiltin(Item)
		goto FLAG_OTHER_BUILTIN_END;
		FLAG_OTHER_BUILTIN_BEGIN:
		{
			break;
		}
		FLAG_OTHER_BUILTIN_END:
		auto it = imported.find(name);
		if (it == imported.end())
		{
			char num[10];
			sprintf(num, "%d", parser->getLineNumber(name));
			lastError += string("Tag <") + name + "> not imported, closed at line " + num + "\n";
		}
	}
	SWITCH_STR_END

	if (parentIsAction && currentData.ref)
	{
		stream << firstItem << '.' << currentData.name << " = " << currentData.name << "\n";
	}
}

void oXmlDelegate::textHandler(void* ctx, const char* s, int len)
{
	codes = s;
}

oXmlLoader::oXmlLoader():_delegate(new oXmlDelegate(&_parser))
{
	_parser.setDelegator(_delegate);
}

oXmlLoader::~oXmlLoader()
{ }

string oXmlLoader::load(const char* filename)
{
	_delegate->begin();
	CCSAXParser::setHeaderHandler(oHandler);
	bool result = _parser.parse(filename);
	CCSAXParser::setHeaderHandler(nullptr);
	_delegate->end();
	return result ? _delegate->getResult() : string();
}

string oXmlLoader::load(const string& xml)
{
	_delegate->begin();
	CCSAXParser::setHeaderHandler(oHandler);
	bool result = _parser.parse(xml.c_str(), (unsigned int)xml.size());
	CCSAXParser::setHeaderHandler(nullptr);
	_delegate->end();
	return result ? _delegate->getResult() : string();
}

string oXmlLoader::getLastError()
{
	const string& parserError = _parser.getLastError();
	const string& dorothyError = _delegate->getLastError();
	if (parserError.empty() && !dorothyError.empty())
	{
		return string("Xml document error\n") + dorothyError;
	}
	return parserError + dorothyError;
}
