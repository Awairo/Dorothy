#include "DorothyModule.h"
#include "CCLuaEngine.h"
#include "tolua++.h"

void CCDrawNode_drawPolygon(
	CCDrawNode* self,
	oVec2* verts,
	int count,
	const ccColor4B& fillColor, float borderWidth,
	const ccColor4B& borderColor)
{
	self->drawPolygon((CCPoint*)verts, count, fillColor, borderWidth, borderColor);
}

void CCDrawNode_drawPolygon(
	CCDrawNode* self,
	oVec2* verts,
	int count,
	const ccColor4B& fillColor)
{
	self->drawPolygon((CCPoint*)verts, count, fillColor, 0, ccColor4B());
}

HANDLER_WRAP_START(oModelHandlerWrapper)
void call(oModel* model) const
{
	CCObject* params[] = { model };
	CCLuaEngine::sharedEngine()->executeFunction(getHandler(), 1, params);
}
HANDLER_WRAP_END
void oModel_addHandler(oModel* model, const string& name, int nHandler)
{
	model->handlers[name] += std::make_pair(oModelHandlerWrapper(nHandler), &oModelHandlerWrapper::call);
}
void oModel_removeHandler(oModel* model, const string& name, int nHandler)
{
	model->handlers[name] -= std::make_pair(oModelHandlerWrapper(nHandler), &oModelHandlerWrapper::call);
}
void oModel_clearHandler(oModel* model, const string& name)
{
	model->handlers[name].Clear();
}
const oVec2& oModel_getKey(oModel* model, uint32 index)
{
	return model->getModelDef()->getKeyPoint(index);
}

HANDLER_WRAP_START(oSensorHandlerWrapper)
void call(oSensor* sensor, oBody* body) const
{
	CCObject* params[] = { sensor, body };
	CCLuaEngine::sharedEngine()->executeFunction(getHandler(), 2, params);
}
HANDLER_WRAP_END

void oSensor_addHandler(oSensor* sensor, uint32 flag, int nHandler)
{
	switch(flag)
	{
	case oSensorEvent::Enter:
		sensor->bodyEnter += std::make_pair(oSensorHandlerWrapper(nHandler), &oSensorHandlerWrapper::call);
		break;
	case oSensorEvent::Leave:
		sensor->bodyLeave += std::make_pair(oSensorHandlerWrapper(nHandler), &oSensorHandlerWrapper::call);
		break;
	}
}
void oSensor_removeHandler(oSensor* sensor, uint32 flag, int nHandler)
{
	switch(flag)
	{
	case oSensorEvent::Enter:
		sensor->bodyEnter -= std::make_pair(oSensorHandlerWrapper(nHandler), &oSensorHandlerWrapper::call);
		break;
	case oSensorEvent::Leave:
		sensor->bodyLeave -= std::make_pair(oSensorHandlerWrapper(nHandler), &oSensorHandlerWrapper::call);
		break;
	}
}
void oSensor_clearHandler(oSensor* sensor, uint32 flag)
{
	switch(flag)
	{
	case oSensorEvent::Enter:
		sensor->bodyEnter.Clear();
		break;
	case oSensorEvent::Leave:
		sensor->bodyLeave.Clear();
		break;
	}
}

HANDLER_WRAP_START(oBodyHandlerWrapper)
void call(oBody* body, const oVec2& point, const oVec2& normal) const
{
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	tolua_pushccobject(L, body);
	tolua_pushusertype(L, new oVec2(point), "oVec2");
	tolua_pushusertype(L, new oVec2(normal), "oVec2");
	CCLuaEngine::sharedEngine()->executeFunction(getHandler(), 3);
}
HANDLER_WRAP_END

void oBody_addHandler(oBody* body, uint32 flag, int nHandler)
{
	switch (flag)
	{
	case oBodyEvent::ContactStart:
		body->contactStart += std::make_pair(oBodyHandlerWrapper(nHandler), &oBodyHandlerWrapper::call);
		break;
	case oBodyEvent::ContactEnd:
		body->contactEnd += std::make_pair(oBodyHandlerWrapper(nHandler), &oBodyHandlerWrapper::call);
		break;
	}
}
void oBody_removeHandler(oBody* body, uint32 flag, int nHandler)
{
	switch (flag)
	{
	case oBodyEvent::ContactStart:
		body->contactStart -= std::make_pair(oBodyHandlerWrapper(nHandler), &oBodyHandlerWrapper::call);
		break;
	case oBodyEvent::ContactEnd:
		body->contactEnd -= std::make_pair(oBodyHandlerWrapper(nHandler), &oBodyHandlerWrapper::call);
		break;
	}
}
void oBody_clearHandler(oBody* body, uint32 flag)
{
	switch (flag)
	{
	case oBodyEvent::ContactStart:
		body->contactStart.Clear();
		break;
	case oBodyEvent::ContactEnd:
		body->contactEnd.Clear();
		break;
	}
}

void oWorld_query(oWorld* world, const CCRect& rect, int nHandler)
{
	world->query(rect,
		[&](oBody* body)
	{
		CCObject* params[] = { body };
		return CCLuaEngine::sharedEngine()->executeFunction(nHandler, 1, params) != 0;
	});
	CCLuaEngine::sharedEngine()->removeScriptHandler(nHandler);
}

void oWorld_cast(oWorld* world, const oVec2& start, const oVec2& end, bool closest, int handler)
{
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	world->cast(start, end, closest,
		[&](oBody* body, const oVec2& point, const oVec2& normal)
	{
		tolua_pushccobject(L, body);
		tolua_pushusertype(L, new oVec2(point), "oVec2");
		tolua_pushusertype(L, new oVec2(normal), "oVec2");
		return CCLuaEngine::sharedEngine()->executeFunction(handler, 3);
	});
	CCLuaEngine::sharedEngine()->removeScriptHandler(handler);
}

bool oAnimationCache_load(const char* filename)
{
	return oSharedAnimationCache.load(filename) != nullptr;
}
bool oAnimationCache_update(const char* name, const char* content)
{
	return oSharedAnimationCache.update(name, content) != nullptr;
}
bool oAnimationCache_unload(const char* filename)
{
	return filename ? oSharedAnimationCache.unload(filename) : oSharedAnimationCache.unload();
}
void oAnimationCache_removeUnused()
{
	oSharedAnimationCache.removeUnused();
}

bool oClipCache_load(const char* filename)
{
	return oSharedClipCache.load(filename) != nullptr;
}
bool oClipCache_update(const char* name, const char* content)
{
	return oSharedClipCache.update(name, content) != nullptr;
}
bool oClipCache_unload(const char* filename)
{
	return filename ? oSharedClipCache.unload(filename) : oSharedClipCache.unload();
}
void oClipCache_removeUnused()
{
	oSharedClipCache.removeUnused();
}
void __oClipCache_getNames(const char* filename)
{
	oClipDef* clipDef = oSharedClipCache.load(filename);
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	lua_createtable(L, clipDef->rects.size(), 0);
	int i = 1;
	for(const auto& item : clipDef->rects)
	{
		lua_pushstring(L,item.first.c_str());
		lua_rawseti(L, -2, i++);
	}
}

bool oEffectCache_load(const char* filename)
{
	return oSharedEffectCache.load(filename);
}
bool oEffectCache_update(const char* content)
{
	return oSharedEffectCache.update(content);
}
bool oEffectCache_unload()
{
	return oSharedEffectCache.unload();
}

bool oParticleCache_load(const char* filename)
{
	return oSharedParticleCache.load(filename) != nullptr;
}
bool oParticleCache_update(const char* name, const char* content)
{
	return oSharedAnimationCache.update(name, content) != nullptr;
}
bool oParticleCache_unload(const char* filename)
{
	return filename ? oSharedParticleCache.unload(filename) : oSharedParticleCache.unload();
}
void oParticleCache_removeUnused()
{
	oSharedParticleCache.removeUnused();
}

bool oModelCache_load(const char* filename)
{
	return oSharedModelCache.load(filename) != nullptr;
}
bool oModelCache_update(const char* name, const char* content)
{
	return oSharedAnimationCache.update(name, content) != nullptr;
}
bool oModelCache_unload(const char* filename)
{
	return filename ? oSharedModelCache.unload(filename) : oSharedModelCache.unload();
}
void oModelCache_removeUnused()
{
	oSharedModelCache.removeUnused();
}

void oCache_removeUnused()
{
	oSharedModelCache.removeUnused();
	oSharedAnimationCache.removeUnused();
	oSharedParticleCache.removeUnused();
	oSharedClipCache.removeUnused();
	CCTextureCache::sharedTextureCache()->removeUnusedTextures();
}

void oCache_clear()
{
	oSharedModelCache.unload();
	oSharedAnimationCache.unload();
	oSharedEffectCache.unload();
	oSharedParticleCache.unload();
	oSharedClipCache.unload();
	CCTextureCache::sharedTextureCache()->removeAllTextures();
	oShareAudioEngine.unload();
}

int oCache_poolCollect()
{
	int collect = 0;
	collect += oVec2::poolCollect();
	collect += oKeyReset::poolCollect();
	collect += oKeyPos::poolCollect();
	collect += oKeyScale::poolCollect();
	collect += oKeyRotate::poolCollect();
	collect += oKeyOpacity::poolCollect();
	collect += oKeySkew::poolCollect();
	collect += oKeyRoll::poolCollect();
	collect += oSequence::poolCollect();
	collect += oSpawn::poolCollect();
	return collect;
}

int oCache_poolSize()
{
	int size = 0;
	size += oVec2::poolSize();
	size += oKeyReset::poolSize();
	size += oKeyPos::poolSize();
	size += oKeyScale::poolSize();
	size += oKeyRotate::poolSize();
	size += oKeyOpacity::poolSize();
	size += oKeySkew::poolSize();
	size += oKeyRoll::poolSize();
	size += oSequence::poolSize();
	size += oSpawn::poolSize();
	return size;
}

void oUnitDef_setActions(oUnitDef* def, int actions[], int count)
{
	def->actions.clear();
	for(int i = 0; i < count; i++)
	{
		def->actions.push_back(actions[i]);
	}
}
void oUnitDef_setInstincts(oUnitDef* def, int instincts[], int count)
{
	def->instincts.clear();
	for(int i = 0; i < count; i++)
	{
		def->instincts.push_back(instincts[i]);
	}
}

HANDLER_WRAP_START(oListenerHandlerWrapper)
void call(oEvent* event) const
{
	void* params[] = { event };
	const char* names[] = { "oEvent" };
	CCLuaEngine::sharedEngine()->executeFunction(getHandler(), 1, params, names);
}
HANDLER_WRAP_END
oListener* oListener_create(const string& name, int handler)
{
	return oListener::create(name, std::make_pair(oListenerHandlerWrapper(handler), &oListenerHandlerWrapper::call));
}

void __oContent_getDirEntries(oContent* self, const char* path, bool isFolder)
{
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	auto dirs = self->getDirEntries(path, isFolder);
	lua_createtable(L, dirs.size(), 0);
	for (size_t i = 0; i < dirs.size(); i++)
	{
		lua_pushstring(L, dirs[i].c_str());
		lua_rawseti(L, -2, i+1);
	}
}

void __oJoint_collision(bool flag)
{
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	oJoint::enableCollision(flag);
	lua_pushvalue(L, 1);
}

CCSprite* CCSprite_createWithClip(const char* clipStr)
{
	if(string(clipStr).find('|') != string::npos)
	{
		return oSharedClipCache.loadSprite(clipStr);
	}
	else if(oFileExt::check(clipStr,oFileExt::Clip))
	{
		oClipDef* def = oSharedClipCache.load(clipStr);
		return CCSprite::create(def->textureFile.c_str());
	}
	return CCSprite::create(clipStr);
}

CCScene* CCScene_createOriented(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionSceneOriented::create(duration, nextScene, orientation);
}
CCScene* CCScene_createRotoZoom(float duration, CCScene* nextScene)
{
	return CCTransitionRotoZoom::create(duration, nextScene);
}
CCScene* CCScene_createJumpZoom(float duration, CCScene* nextScene)
{
	return CCTransitionJumpZoom::create(duration, nextScene);
}
CCScene* CCScene_createMove(float duration, CCScene* nextScene, tOrientation orientation)
{
	switch(orientation)
	{
	case kCCTransitionOrientationLeftOver:
		return CCTransitionMoveInL::create(duration, nextScene);
	case kCCTransitionOrientationRightOver:
		return CCTransitionMoveInR::create(duration, nextScene);
	case kCCTransitionOrientationUpOver:
		return CCTransitionMoveInT::create(duration, nextScene);
	case kCCTransitionOrientationDownOver:
		return CCTransitionMoveInB::create(duration, nextScene);
	}
	return nullptr;
}
CCScene* CCScene_createSlide(float duration, CCScene* nextScene, tOrientation orientation)
{
	switch(orientation)
	{
	case kCCTransitionOrientationLeftOver:
		return CCTransitionSlideInL::create(duration, nextScene);
	case kCCTransitionOrientationRightOver:
		return CCTransitionSlideInR::create(duration, nextScene);
	case kCCTransitionOrientationUpOver:
		return CCTransitionSlideInT::create(duration, nextScene);
	case kCCTransitionOrientationDownOver:
		return CCTransitionSlideInB::create(duration, nextScene);
	}
	return nullptr;
}
CCScene* CCScene_createShrinkGrow(float duration, CCScene* nextScene)
{
	return CCTransitionShrinkGrow::create(duration, nextScene);
}
CCScene* CCScene_createFlipX(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionFlipX::create(duration, nextScene);
}
CCScene* CCScene_createFlipY(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionFlipY::create(duration, nextScene);
}
CCScene* CCScene_createFlipAngular(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionFlipAngular::create(duration, nextScene);
}
CCScene* CCScene_createZoomFlipX(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionZoomFlipX::create(duration, nextScene, orientation);
}
CCScene* CCScene_createZoomFlipY(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionZoomFlipY::create(duration, nextScene, orientation);
}
CCScene* CCScene_createZoomFlipAngular(float duration, CCScene* nextScene, tOrientation orientation)
{
	return CCTransitionZoomFlipAngular::create(duration, nextScene, orientation);
}
CCScene* CCScene_createFade(float duration, CCScene* nextScene, const ccColor3B& color)
{
	return CCTransitionFade::create(duration, nextScene, color);
}
CCScene* CCScene_createCrossFade(float duration, CCScene* nextScene)
{
	return CCTransitionCrossFade::create(duration, nextScene);
}
CCScene* CCScene_createTurnOffTiles(float duration, CCScene* nextScene)
{
	return CCTransitionTurnOffTiles::create(duration, nextScene);
}
CCScene* CCScene_createSplitCols(float duration, CCScene* nextScene)
{
	return CCTransitionSplitCols::create(duration, nextScene);
}
CCScene* CCScene_createSplitRows(float duration, CCScene* nextScene)
{
	return CCTransitionSplitRows::create(duration, nextScene);
}
CCScene* CCScene_createFadeTiles(float duration, CCScene* nextScene, tOrientation orientation)
{
	switch(orientation)
	{
	case kCCTransitionOrientationLeftOver:
		return CCTransitionFadeBL::create(duration, nextScene);
	case kCCTransitionOrientationRightOver:
		return CCTransitionFadeTR::create(duration, nextScene);
	case kCCTransitionOrientationUpOver:
		return CCTransitionFadeUp::create(duration, nextScene);
	case kCCTransitionOrientationDownOver:
		return CCTransitionFadeDown::create(duration, nextScene);
	}
	return nullptr;
}
CCScene* CCScene_createPageTurn(float duration, CCScene* nextScene, bool backward)
{
	return CCTransitionPageTurn::create(duration, nextScene, backward);
}
CCScene* CCScene_createProgressCCW(float duration, CCScene* nextScene)
{
	return CCTransitionProgressRadialCCW::create(duration, nextScene);
}
CCScene* CCScene_createProgressCW(float duration, CCScene* nextScene)
{
	return CCTransitionProgressRadialCW::create(duration, nextScene);
}
CCScene* CCScene_createProgressH(float duration, CCScene* nextScene)
{
	return CCTransitionProgressHorizontal::create(duration, nextScene);
}
CCScene* CCScene_createProgressV(float duration, CCScene* nextScene)
{
	return CCTransitionProgressVertical::create(duration, nextScene);
}
CCScene* CCScene_createProgressIO(float duration, CCScene* nextScene)
{
	return CCTransitionProgressInOut::create(duration, nextScene);
}
CCScene* CCScene_createProgressOI(float duration, CCScene* nextScene)
{
	return CCTransitionProgressOutIn::create(duration, nextScene);
}

CCCardinalSplineTo* CCCardinalSplineTo_create(float duration, const oVec2 points[], int count, float tension)
{
	CCPointArray* array = CCPointArray::create(count);
	for(int i = 0; i < count; i++)
	{
		array->addControlPoint(points[i]);
	}
	return CCCardinalSplineTo::create(duration, array, tension);
}
CCCardinalSplineBy* CCCardinalSplineBy_create(float duration, const oVec2 points[], int count, float tension)
{
	CCPointArray* array = CCPointArray::create(count);
	for(int i = 0; i < count; i++)
	{
		array->addControlPoint(points[i]);
	}
	return CCCardinalSplineBy::create(duration, array, tension);
}
CCCatmullRomTo* CCCatmullRomTo_create(float duration, const oVec2 points[], int count)
{
	CCPointArray* array = CCPointArray::create(count);
	for(int i = 0; i < count; i++)
	{
		array->addControlPoint(points[i]);
	}
	return CCCatmullRomTo::create(duration, array);
}
CCCatmullRomBy* CCCatmullRomBy_create(float duration, const oVec2 points[], int count)
{
	CCPointArray* array = CCPointArray::create(count);
	for(int i = 0; i < count; i++)
	{
		array->addControlPoint(points[i]);
	}
	return CCCatmullRomBy::create(duration, array);
}

CCActionInterval* CCTile_createFadeOut(float duration, CCSize gridSize, tOrientation orientation)
{
	switch(orientation)
	{
	case kCCTransitionOrientationLeftOver:
		return CCFadeOutBLTiles::create(duration, gridSize);
	case kCCTransitionOrientationRightOver:
		return CCFadeOutTRTiles::create(duration, gridSize);
	case kCCTransitionOrientationUpOver:
		return CCFadeOutUpTiles::create(duration, gridSize);
	case kCCTransitionOrientationDownOver:
		return CCFadeOutDownTiles::create(duration, gridSize);
	}
	return nullptr;
}

CCArray* CCArray_create(CCObject* object[], int count)
{
	CCArray* array = CCArray::createWithCapacity(count);
	for(int i = 0; i < count; i++)
	{
		array->addObject(object[i]);
	}
	return array;
}
unsigned int CCArray_index(CCArray* array, CCObject* object)
{
	return array->indexOfObject(object) + 1;
}
CCObject* CArray_get(CCArray* array, unsigned int index)
{
	return array->objectAtIndex(index - 1);
}
void CArray_insert(CCArray* array, CCObject* object, unsigned int index)
{
	array->insertObject(object, index - 1);
}
void CArray_removeAt(CCArray* array, unsigned int index)
{
	array->removeObjectAtIndex(index - 1);
}
void CArray_exchange(CCArray* array, unsigned int index1, unsigned int index2)
{
	array->exchangeObjectAtIndex(index1 - 1, index2 - 1);
}
void CArray_fastRemoveAt(CCArray* array, unsigned int index)
{
	array->fastRemoveObjectAtIndex(index - 1);
}
void CArray_set(CCArray* array, unsigned int index, CCObject* object)
{
	array->replaceObjectAtIndex(index - 1, object);
}

CCTexture2D* CCTextureCache_add(CCTextureCache* self, CCRenderTexture* renderTexture, const char* name)
{
	CCImage* image = renderTexture->newCCImage();
	CCTexture2D* texture = self->addUIImage(image, name);
	delete image;
	return texture;
}

int CCDictionary_get(lua_State* L)
{
	/* 1 self, 2 key */
#ifndef TOLUA_RELEASE
	tolua_Error tolua_err;
	if (!tolua_isusertype(L, 1, "CCDictionary", 0, &tolua_err))
	{
		goto tolua_lerror;
	}
#endif
    {
	CCDictionary* self = (CCDictionary*)tolua_tousertype(L, 1, 0);
#ifndef TOLUA_RELEASE
	if (!self) tolua_error(L, "invalid 'self' in function 'CCDictionary_get'", nullptr);
#endif
	CCObject* object = nullptr;
	if (lua_isnumber(L, 2))
	{
		int key = (int)lua_tonumber(L, 2);
		object = self->objectForKey(key);
	}
	else if (lua_isstring(L, 2))
	{
		const char* key = lua_tostring(L, 2);
		object = self->objectForKey(key);
	}
	if (object)
	{
		CCFloat* number = CCLuaCast<CCFloat>(object);
		if (number)
		{
			lua_pushnumber(L, number->getValue());
			return 1;
		}
		CCBool* boolean = CCLuaCast<CCBool>(object);
		if (boolean)
		{
			lua_pushboolean(L, boolean->getValue() ? 1 : 0);
			return 1;
		}
		CCString* str = CCLuaCast<CCString>(object);
		if (str)
		{
			lua_pushstring(L, str->getCString());
			return 1;
		}
		tolua_pushccobject(L, object);
		return 1;
	}
	else
	{
		lua_pushnil(L);
		return 1;
	}
    }
#ifndef TOLUA_RELEASE
tolua_lerror:
	tolua_error(L, "#ferror in function 'CCDictionary_get'.", &tolua_err);
	return 0;
#endif
}

int CCDictionary_set(lua_State* L)
{
	/* 1 self, 2 key, 3 value */
#ifndef TOLUA_RELEASE
	tolua_Error tolua_err;
	if (!tolua_isusertype(L, 1, "CCDictionary", 0, &tolua_err))
	{
		goto tolua_lerror;
	}
#endif
    {
	CCDictionary* self = (CCDictionary*)tolua_tousertype(L, 1, 0);
#ifndef TOLUA_RELEASE
	if (!self) tolua_error(L, "invalid 'self' in function 'CCDictionary_set'", nullptr);
#endif
	CCObject* object = nullptr;
	if (lua_isnumber(L, 3))
	{
		object = CCFloat::create((float)lua_tonumber(L, 3));
	}
	else if (lua_isboolean(L, 3))
	{
		object = CCBool::create(lua_toboolean(L, 3) != 0);
	}
	else if (lua_isstring(L, 3))
	{
		object = CCString::create(lua_tostring(L, 3));
	}
	else if (tolua_isccobject(L, 3))
	{
		object = (CCObject*)tolua_tousertype(L, 3, 0);
	}
#ifndef TOLUA_RELEASE
	else if (!lua_isnil(L, 3))
	{
		tolua_error(L, "CCDictionary can only store number, boolean, string and CCObject.", nullptr);
	}
#endif
	if (lua_isnumber(L, 2))
	{
		int key = (int)lua_tonumber(L, 2);
		if (object) self->setObject(object, key);
		else self->removeObjectForKey(key);
	}
	else if (lua_isstring(L, 2))
	{
		const char* key = lua_tostring(L, 2);
		if (object) self->setObject(object, key);
		else self->removeObjectForKey(key);
	}
	return 0;
    }
#ifndef TOLUA_RELEASE
tolua_lerror :
	tolua_error(L, "#ferror in function 'CCDictionary_set'.", &tolua_err);
	return 0;
#endif
}

int CCDictionary_keys(lua_State* L)
{
	CCDictionary* self = (CCDictionary*)tolua_tousertype(L, 1, 0);
#ifndef TOLUA_RELEASE
	if (!self) tolua_error(L, "invalid 'self' in accessing variable 'keys'", nullptr);
#endif
	CCArray* keys = self->allKeys();
	lua_createtable(L, keys->count(), 0);
	int i = 1;
	CCARRAY_START(CCObject, key, keys)
	{
		if (key->getLuaType() == CCLuaType<CCString>())
		{
			lua_pushstring(L, ((CCString*)key)->getCString());
			lua_rawseti(L, -2, i++);
		}
		else if (key->getLuaType() == CCLuaType<CCInteger>())
		{
			lua_pushinteger(L, ((CCInteger*)key)->getValue());
			lua_rawseti(L, -2, i++);
		}
	}
	CCARRAY_END
	return 1;
}

int CCDictionary_randomObject(lua_State* L)
{
	CCDictionary* self = (CCDictionary*)tolua_tousertype(L, 1, 0);
#ifndef TOLUA_RELEASE
	if (!self) tolua_error(L, "invalid 'self' in accessing variable 'randomObject'", nullptr);
#endif
	CCObject* object = self->randomObject();
	CCFloat* number = CCLuaCast<CCFloat>(object);
	if (number)
	{
		lua_pushnumber(L, number->getValue());
		return 1;
	}
	CCBool* boolean = CCLuaCast<CCBool>(object);
	if (boolean)
	{
		lua_pushboolean(L, boolean->getValue() ? 1 : 0);
		return 1;
	}
	CCString* str = CCLuaCast<CCString>(object);
	if (str)
	{
		lua_pushstring(L, str->getCString());
		return 1;
	}
	tolua_pushccobject(L, object);
	return 1;
}

void __oModelCache_getData(const char* filename)
{
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	oModelDef* modelDef = oSharedModelCache.load(filename);
	if(!modelDef)
	{
		lua_pushnil(L);
		return;
	}
	auto lua_setFloat = [&](int index, float value)
	{
		lua_pushnumber(L, value);
		lua_rawseti(L, -2, index);
	};
	auto lua_setInt = [&](int index, int value)
	{
		lua_pushinteger(L, value);
		lua_rawseti(L, -2, index);
	};
	auto lua_setBool = [&](int index, bool value)
	{
		lua_pushboolean(L, value);
		lua_rawseti(L, -2, index);
	};
	auto lua_setString = [&](int index, const char* value)
	{
		lua_pushstring(L, value);
		lua_rawseti(L, -2, index);
	};
	auto lua_setUserType = [&](int index, void* value, const char* typeName)
	{
		tolua_pushusertype(L, value, typeName);
		lua_rawseti(L, -2, index);
	};
	function<void(oSpriteDef*)> visitSpriteDef = [&](oSpriteDef* parent)
	{
		lua_createtable(L, 17, 0);
		lua_setFloat(1, parent->anchorX);
		lua_setFloat(2, parent->anchorY);
		lua_setString(3, parent->clip.c_str());
		lua_setString(4, parent->name.c_str());
		lua_setFloat(5, parent->opacity);
		lua_setFloat(6, parent->rotation);
		lua_setFloat(7, parent->scaleX);
		lua_setFloat(8, parent->scaleY);
		lua_setFloat(9, parent->skewX);
		lua_setFloat(10, parent->skewY);
		lua_setFloat(11, parent->x);
		lua_setFloat(12, parent->y);
		/*["looks"]*/
		lua_createtable(L, parent->looks.size(), 0);
		for(int i = 0; i <(int)parent->looks.size(); i++)
		{
			lua_pushinteger(L, parent->looks[i]);
			lua_rawseti(L, -2, i + 1);
		}
		lua_rawseti(L, -2, 13);
		/*["animationDefs"]*/
		lua_createtable(L, parent->animationDefs.size(), 0);
		for(int defIndex = 0; defIndex <(int)parent->animationDefs.size(); defIndex++)
		{
			oModelAnimationDef* def = parent->animationDefs[defIndex];
			/* nullptr */
			if(!def)
			{
				lua_pushboolean(L, 0);
				lua_rawseti(L, -2, defIndex + 1);
				continue;
			}
			/* oKeyAnimationDef */
			oKeyAnimationDef* keyDef = dynamic_cast<oKeyAnimationDef*>(def);
			if(keyDef)
			{
				auto& frames = keyDef->getFrames();
				lua_createtable(L, frames.size()+1, 0);
				lua_setInt(1, 1);
				for(int i = 0; i <(int)frames.size(); i++)
				{
					oKeyFrameDef* frame = frames[i];
					lua_createtable(L, 15, 0);
					lua_setFloat(1, frame->x);
					lua_setFloat(2, frame->y);
					lua_setFloat(3, frame->scaleX);
					lua_setFloat(4, frame->scaleY);
					lua_setFloat(5, frame->skewX);
					lua_setFloat(6, frame->skewY);
					lua_setFloat(7, frame->rotation);
					lua_setFloat(8, frame->opacity);
					lua_setBool(9, frame->visible);
					lua_setInt(10, frame->easeOpacity);
					lua_setInt(11, frame->easePos);
					lua_setInt(12, frame->easeRotation);
					lua_setInt(13, frame->easeScale);
					lua_setInt(14, frame->easeSkew);
					lua_setFloat(15, frame->duration);
					lua_rawseti(L, -2, i + 2);
				}
				lua_rawseti(L, -2, defIndex + 1);
				continue;
			}
			/* oFrameAnimationDef */
			oFrameAnimationDef* frameDef = dynamic_cast<oFrameAnimationDef*>(def);
			if(frameDef)
			{
				lua_createtable(L, 4, 0);
				lua_setInt(1, 2);
				lua_setString(2, frameDef->getFile().c_str());
				lua_setFloat(3, frameDef->delay);
				lua_rawseti(L, -2, defIndex + 1);
				continue;
			}
		}
		lua_rawseti(L, -2, 14);
		/*["children"]*/
		lua_createtable(L, parent->children.size(), 0);
		for(int i = 0; i <(int)parent->children.size(); i++)
		{
			visitSpriteDef(parent->children[i]);
			lua_rawseti(L, -2, i + 1);
		}
		lua_rawseti(L, -2, 15);
		/*["front"]*/
		lua_setBool(16, parent->front);
	};

	oSpriteDef* root = modelDef->getRoot();
	if(root)
	{
		visitSpriteDef(root);
		lua_setBool(17, modelDef->isFaceRight());
		lua_setBool(18, modelDef->isBatchUsed());
		lua_setUserType(19, new CCSize(modelDef->getSize()), "CCSize");
		lua_setString(20, modelDef->getClipFile().c_str());
		/*["keys"]*/
		lua_createtable(L, modelDef->getKeyPointCount(), 0);
		for(int i = 0; i < modelDef->getKeyPointCount(); i++)
		{
			tolua_pushusertype(L, new oVec2(modelDef->getKeyPoint(i)), "oVec2");
			lua_rawseti(L, -2, i + 1);
		}
		lua_rawseti(L, -2, 21);
		/*["animationNames"]*/
		lua_newtable(L);
		for(const auto& pair : modelDef->getAnimationIndexMap())
		{
			lua_pushstring(L, pair.first.c_str());
			lua_pushinteger(L, pair.second);
			lua_rawset(L, -3);
		}
		lua_rawseti(L, -2, 22);
		/*["lookNames"]*/
		lua_newtable(L);
		for(const auto& pair : modelDef->getLookIndexMap())
		{
			lua_pushstring(L, pair.first.c_str());
			lua_pushinteger(L, pair.second);
			lua_rawset(L, -3);
		}
		lua_rawseti(L, -2, 23);
	}
	else lua_pushnil(L);
}

void oModelCache_save(const char* itemName, const char* targetName)
{
	oSharedContent.saveToFile(targetName, oSharedModelCache.load(itemName)->toXml());
}

oModelDef* oModelCache_loadData(const char* filename, int tableIndex)
{
	lua_State* L = CCLuaEngine::sharedEngine()->getState();
	
	auto lua_getFloat = [&](int index)->float
	{
		lua_rawgeti(L, -1, index);
		float v =(float)lua_tonumber(L, -1);
		lua_pop(L, 1);
		return v;
	};
	auto lua_getInt = [&](int index)->int
	{
		lua_rawgeti(L, -1, index);
		int v = lua_tointeger(L, -1);
		lua_pop(L, 1);
		return v;
	};
	auto lua_getBool = [&](int index)->bool
	{
		lua_rawgeti(L, -1, index);
		bool v =(lua_toboolean(L, -1) != 0);
		lua_pop(L, 1);
		return v;
	};
	auto lua_getString = [&](int index)->const char*
	{
		lua_rawgeti(L, -1, index);
		const char* v = lua_tostring(L, -1);
		lua_pop(L, 1);
		return v;
	};
	auto lua_getUserType = [&](int index)->void*
	{
		lua_rawgeti(L, -1, index);
		void* v =(*(void**)(lua_touserdata(L, -1)));
		lua_pop(L, 1);
		return v;
	};
	lua_pushvalue(L, tableIndex);// push content

	bool isFaceRight = lua_getBool(17);
	bool isBatchUsed = lua_getBool(18);
	CCSize size = *(CCSize*)lua_getUserType(19);
	string clipFile = lua_getString(20);
	oClipDef* clipDef = oSharedClipCache.load(clipFile.c_str());
	CCTexture2D* texture = oSharedContent.loadTexture(clipDef->textureFile.c_str());
	/*["keys"]*/
	lua_rawgeti(L, -1, 21);// push keys
	vector<oVec2> keys(lua_objlen(L, -1));
	for(size_t i = 0; i < keys.size(); i++)
	{
		lua_rawgeti(L, -1, i + 1);
		oVec2* v =(*(oVec2**)(lua_touserdata(L, -1)));
		keys[i] = *v;
		lua_pop(L, 1);
	}
	lua_pop(L, 1);// pop keys
	/*["animationNames"]*/
	lua_rawgeti(L, -1, 22);// push animationNames
	unordered_map<string, int> animationNames;
	int top = lua_gettop(L);
	for(lua_pushnil(L); lua_next(L, top) != 0; lua_pop(L, 1))
	{
		animationNames[lua_tostring(L, -2)] = lua_tointeger(L, -1);
	}
	lua_pop(L, 1);// pop animationNames
	/*["lookNames"]*/
	lua_rawgeti(L, -1, 23);// push lookNames
	unordered_map<string, int> lookNames;
	top = lua_gettop(L);
	for(lua_pushnil(L); lua_next(L, top) != 0; lua_pop(L, 1))
	{
		lookNames[lua_tostring(L, -2)] = lua_tointeger(L, -1);
	}
	lua_pop(L, 1);// pop lookNames
	/*oSpriteDef*/
	function<oSpriteDef*()> visitSpriteDef = [&]()->oSpriteDef*
	{
		oSpriteDef* spriteDef = new oSpriteDef();
		spriteDef->texture = texture;
		spriteDef->anchorX = lua_getFloat(1);
		spriteDef->anchorY = lua_getFloat(2);
		spriteDef->clip = lua_getString(3);
		spriteDef->rect = spriteDef->clip == "" ? CCRect::zero : *clipDef->rects[spriteDef->clip];
		spriteDef->name = lua_getString(4);
		spriteDef->opacity = lua_getFloat(5);
		spriteDef->rotation = lua_getFloat(6);
		spriteDef->scaleX = lua_getFloat(7);
		spriteDef->scaleY = lua_getFloat(8);
		spriteDef->skewX = lua_getFloat(9);
		spriteDef->skewY = lua_getFloat(10);
		spriteDef->x = lua_getFloat(11);
		spriteDef->y = lua_getFloat(12);
		/*["looks"]*/
		lua_rawgeti(L, -1, 13);// puah looks
		for(size_t i = 0, len = lua_objlen(L, -1); i < len; i++)
		{
			lua_rawgeti(L, -1, i + 1);
			spriteDef->looks.push_back(lua_tointeger(L, -1));
			lua_pop(L, 1);
		}
		lua_pop(L, 1);// pop looks
		/*["animationDefs"]*/
		lua_rawgeti(L, -1, 14);// push animationDefs
		for(size_t defIndex = 0, len = lua_objlen(L, -1); defIndex < len; defIndex++)
		{
			lua_rawgeti(L, -1, defIndex + 1);// push animationDef or boolean
			/* nullptr */
			if(lua_isboolean(L, -1))
			{
				spriteDef->animationDefs.push_back(nullptr);
				lua_pop(L, 1);// pop boolean
				continue;
			}
			int type = lua_getInt(1);
			/* oKeyAnimationDef */
			if(type == 1)
			{
				oKeyAnimationDef* keyAnimationDef = new oKeyAnimationDef();
				for(size_t i = 0, len = lua_objlen(L, -1)-1; i < len; i++)
				{
					lua_rawgeti(L, -1, i + 2);// push frameDef
					oKeyFrameDef* frameDef = new oKeyFrameDef();
					frameDef->x = lua_getFloat(1);
					frameDef->y = lua_getFloat(2);
					frameDef->scaleX = lua_getFloat(3);
					frameDef->scaleY = lua_getFloat(4);
					frameDef->skewX = lua_getFloat(5);
					frameDef->skewY = lua_getFloat(6);
					frameDef->rotation = lua_getFloat(7);
					frameDef->opacity = lua_getFloat(8);
					frameDef->visible = lua_getBool(9);
					frameDef->easeOpacity = lua_getInt(10);
					frameDef->easePos = lua_getInt(11);
					frameDef->easeRotation = lua_getInt(12);
					frameDef->easeScale = lua_getInt(13);
					frameDef->easeSkew = lua_getInt(14);
					frameDef->duration = lua_getFloat(15);
					keyAnimationDef->add(frameDef);
					lua_pop(L, 1);// pop frameDef
				}
				spriteDef->animationDefs.push_back(keyAnimationDef);
			}
			/* oFrameAnimationDef */
			else if(type == 2)
			{
				oFrameAnimationDef* frameAnimationDef = new oFrameAnimationDef();
				frameAnimationDef->setFile(lua_getString(2));
				frameAnimationDef->delay = lua_getFloat(3);
				spriteDef->animationDefs.push_back(frameAnimationDef);
			}
			lua_pop(L, 1);// pop animationDef
		}
		lua_pop(L, 1);// pop animationDefs
		/* ["children"] */
		lua_rawgeti(L, -1, 15);// push children
		for(size_t i = 0, len = lua_objlen(L, -1); i < len; i++)
		{
			lua_rawgeti(L, -1, i + 1);// push childDef
			spriteDef->children.push_back(visitSpriteDef());
			lua_pop(L, 1);// pop childDef
		}
		lua_pop(L, 1);// pop children
		/* ["front"] */
		spriteDef->front = lua_getBool(16);
		return spriteDef;
	};
	oSpriteDef* root = visitSpriteDef();
	oModelDef* modelDef = new oModelDef(isFaceRight, isBatchUsed, size, clipFile, texture, root, keys, animationNames, lookNames);
	modelDef->autorelease();
	lua_pop(L, 1);// pop content
	return oSharedModelCache.update(filename, modelDef);
}

CCCall* CCCall::create(int nHandler)
{
	CCCall* pRet = new CCCall();
	pRet->_scriptHandler = nHandler;
	pRet->autorelease();
	return pRet;
}
CCCall::~CCCall()
{
	if(_scriptHandler)
	{
		CCScriptEngine::sharedEngine()->removeScriptHandler(_scriptHandler);
	}
}
CCObject* CCCall::copyWithZone(CCZone *pZone)
{
	return nullptr;
}
void CCCall::update(float time)
{
	if(time > 0.0f)
	{
		this->execute();
	}
}
void CCCall::execute()
{
	if(_scriptHandler)
	{
		CCScriptEngine::sharedEngine()->executeFunction(_scriptHandler);
	}
}

class oTextFieldDelegate: public CCTextFieldDelegate
{
public:
	oRef<oScriptHandler> handler;
	virtual bool onTextFieldAttachWithIME(CCTextFieldTTF * sender)
	{
		if(handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			tolua_pushccobject(L, sender);
			lua_pushinteger(L, oTextFieldEvent::Attach);
			return CCLuaEngine::sharedEngine()->executeFunction(handler->get(), 2) != 0;
		}
		return false;
	}
	virtual bool onTextFieldDetachWithIME(CCTextFieldTTF * sender)
	{
		if(handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			tolua_pushccobject(L, sender);
			lua_pushinteger(L, oTextFieldEvent::Detach);
			return CCLuaEngine::sharedEngine()->executeFunction(handler->get(), 2) != 0;
		}
		return false;
	}
	virtual bool onTextFieldInsertText(CCTextFieldTTF * sender, const char * text, int nLen)
	{
		if(handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			tolua_pushccobject(L, sender);
			lua_pushinteger(L, oTextFieldEvent::Insert);
			lua_pushstring(L, text);
			return CCLuaEngine::sharedEngine()->executeFunction(handler->get(), 3) == 0;
		}
		return false;
	}
	virtual void onTextFieldInserted(CCTextFieldTTF* sender, const char* text)
	{
		if(handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			tolua_pushccobject(L, sender);
			lua_pushinteger(L, oTextFieldEvent::Inserted);
			lua_pushstring(L, text);
			CCLuaEngine::sharedEngine()->executeFunction(handler->get(), 3);
		}
	}
	virtual bool onTextFieldDeleteBackward(CCTextFieldTTF * sender, const char * delText, int nLen)
	{
		if(handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			tolua_pushccobject(L, sender);
			lua_pushinteger(L, oTextFieldEvent::Delete);
			lua_pushstring(L, delText);
			return CCLuaEngine::sharedEngine()->executeFunction(handler->get(), 3) == 0;
		}
		return false;
	}
	virtual void onTextFieldDeleted(CCTextFieldTTF* sender, const char* delText)
	{
		if(handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			tolua_pushccobject(L, sender);
			lua_pushinteger(L, oTextFieldEvent::Deleted);
			lua_pushstring(L, delText);
			CCLuaEngine::sharedEngine()->executeFunction(handler->get(), 3);
		}
	}
};

CCTextFieldTTF* CCTextFieldTTF_create(const char* placeholder, const char* fontName, float fontSize)
{
	CCTextFieldTTF* textField = CCTextFieldTTF::textFieldWithPlaceHolder(placeholder, fontName, fontSize);
	oTextFieldDelegate* delegate = new oTextFieldDelegate();
	delegate->autorelease();
	textField->setDelegate(delegate);
	return textField;
}
void CCTextFieldTTF_registerInputHandler(CCTextFieldTTF* textField, int handler)
{
	oTextFieldDelegate* delegate =(oTextFieldDelegate*)(textField->getDelegate());
	delegate->handler = oScriptHandler::create(handler);
}
void CCTextFieldTTF_unregisterInputHandler(CCTextFieldTTF* textField)
{
	oTextFieldDelegate* delegate =(oTextFieldDelegate*)(textField->getDelegate());
	delegate->handler = nullptr;
}

CCRenderTexture* CCRenderTexture_create(int w, int h, bool withDepthStencil)
{
	return CCRenderTexture::create(w, h, kCCTexture2DPixelFormat_RGBA8888, withDepthStencil ? GL_DEPTH24_STENCIL8 : 0);
}

int __olua_loadfile(lua_State* L, const char* filename)
{
	unsigned long codeBufferSize = 0;
	unsigned char* codeBuffer = CCFileUtils::sharedFileUtils()->getFileData(filename, "rb", &codeBufferSize);
	if (codeBuffer)
	{
		if (luaL_loadbuffer(L, (char*)codeBuffer, codeBufferSize, filename) != 0)
		{
			delete[] codeBuffer;
			luaL_error(L, "error loading module %s from file %s :\n\t%s",
				lua_tostring(L, 1), filename, lua_tostring(L, -1));
		}
		delete [] codeBuffer;
		return 0;
	}
	else
	{
		CCLog("can not get file data of %s", filename);
		return 1;
	}
}

int __olua_dofile(lua_State* L, const char* filename)
{
	return __olua_loadfile(L, filename) || lua_pcall(L, 0, LUA_MULTRET, 0);
}

class oImageAsyncLoader: public CCObject
{
public:
	void callback(CCObject* object)
	{
		if (_handler)
		{
			lua_State* L = CCLuaEngine::sharedEngine()->getState();
			lua_pushstring(L, _name.c_str());
			CCLuaEngine::sharedEngine()->executeFunction(_handler->get(), 1);
		}
	}
	static oImageAsyncLoader* create(const char* filename, int handler)
	{
		oImageAsyncLoader* loader = new oImageAsyncLoader();
		loader->_name = filename;
		if (handler)
		{
			loader->_handler = oScriptHandler::create(handler);
		}
		loader->autorelease();
		return loader;
	}
private:
	string _name;
	oRef<oScriptHandler> _handler;
};

int CCTextureCache_loadAsync(lua_State* L)
{
	/* 1 self, 2 filename, 3 function */
#ifndef TOLUA_RELEASE
	tolua_Error tolua_err;
	if (
		!tolua_isusertype(L, 1, "CCTextureCache", 0, &tolua_err) ||
		!(tolua_isstring(L, 2, 0, &tolua_err) || tolua_istable(L,2,0,&tolua_err)) ||
		!(toluafix_isfunction(L, 3, &tolua_err) || tolua_isnoobj(L, 3, &tolua_err)) ||
		!tolua_isnoobj(L, 4, &tolua_err)
		)
	{
		goto tolua_lerror;
	}
#endif
    {
	CCTextureCache* self = (CCTextureCache*)tolua_tousertype(L, 1, 0);
#ifndef TOLUA_RELEASE
	if (!self) tolua_error(L, "invalid 'self' in function 'CCTextureCache_loadAsync'", nullptr);
#endif
	if (lua_isstring(L, 2))
	{
		const char* filename = ((const char*)tolua_tostring(L, 2, 0));
		int nHandler = lua_gettop(L) < 3 ? 0 : toluafix_ref_function(L, 3);
		oImageAsyncLoader* loader = oImageAsyncLoader::create(filename, nHandler);
		self->addImageAsync(filename, loader, callfuncO_selector(oImageAsyncLoader::callback));
	}
	else if (lua_istable(L, 2))
	{
		int length = lua_objlen(L, 2);
		for (int i = 0; i < length; i++)
		{
			lua_rawgeti(L, 2, i + 1);
			const char* filename = lua_tostring(L, -1);
			int nHandler = lua_gettop(L) < 3 ? 0 : toluafix_ref_function(L, 3);
			oImageAsyncLoader* loader = oImageAsyncLoader::create(filename, nHandler);
			self->addImageAsync(filename, loader, callfuncO_selector(oImageAsyncLoader::callback));
			lua_pop(L, 1);
		}
	}
	return 0;
    }
#ifndef TOLUA_RELEASE
tolua_lerror :
	tolua_error(L, "#ferror in function 'CCTextureCache_loadAsync'.", &tolua_err);
	return 0;
#endif
}