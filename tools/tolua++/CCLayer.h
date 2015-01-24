class CCLayer: public CCNode
{
	enum
	{
		TouchesAllAtOnce,
		TouchesOneByOne
	};
	tolua_property__bool bool touchEnabled;
	tolua_property__bool bool accelerometerEnabled;
	tolua_property__bool bool keypadEnabled;
	tolua_property__common int touchMode;
	tolua_property__common int touchPriority;

	void registerScriptTouchHandler @ registerTouchHandler(tolua_function nHandler,
									bool bIsMultiTouches = false,
									int nPriority = 0,
									bool bSwallowsTouches = false);
	void unregisterScriptTouchHandler @ unregisterTouchHandler();

	void registerScriptKeypadHandler @ registerKeypadHandler(tolua_function nHandler);
	void unregisterScriptKeypadHandler @ unregisterKeypadHandler();

	void registerScriptAccelerateHandler @ registerAccelerateHandler(tolua_function nHandler);
	void unregisterScriptAccelerateHandler @ unregisterAccelerateHandler();

	static CCLayer* create();
};

class CCLayerColor: public CCLayer
{
	tolua_property__common ccBlendFunc blendFunc;
	static CCLayerColor* create(ccColor4 color, float width, float height);
	static CCLayerColor* create(ccColor4 color);
};

class CCLayerGradient: public CCLayer
{
	tolua_property__common ccBlendFunc blendFunc;
	tolua_property__common ccColor3 startColor;
	tolua_property__common ccColor3 endColor;
	tolua_property__common float startOpacity;
	tolua_property__common float endOpacity;
	tolua_property__common oVec2 vector;
	tolua_property__bool bool compressedInterpolation;

	static CCLayerGradient* create(ccColor4 start, ccColor4 end, oVec2 v);
	static CCLayerGradient* create(ccColor4 start, ccColor4 end);
	static CCLayerGradient* create();
};
