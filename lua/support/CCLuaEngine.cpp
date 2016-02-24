/****************************************************************************
 Copyright(c) 2011 cocos2d-x.org

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files(the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "CCLuaEngine.h"
#include "cocos2d.h"
#include "cocoa/CCArray.h"
#include "basics/CCScheduler.h"
#include "LuaBinding.h"
#include "DorothyXml.h"
#include "DorothyModule.h"

NS_CC_BEGIN

static int g_callFromLua = 0;

static int cclua_print(lua_State* L)
{
	int nargs = lua_gettop(L);
	string t;
	for (int i = 1; i <= nargs; i++)
	{
		if (lua_isnone(L, i)) t += "none";
		else if (lua_isnil(L, i)) t += "nil";
		else if (lua_isboolean(L, i))
		{
			if (lua_toboolean(L, i) != 0) t += "true";
			else t += "false";
		}
		else if (lua_isfunction(L, i)) t += "function";
		else if (lua_islightuserdata(L, i)) t += "lightuserdata";
		else if (lua_isthread(L, i)) t += "thread";
		else
		{
			const char* str = lua_tostring(L, i);
			if (str) t += lua_tostring(L, i);
			else t += tolua_typename(L, i);
		}
		if (i != nargs) t += "\t";
	}
	CCLog("%s", t.c_str());
	return 0;
}

static int cclua_traceback(lua_State* L)
{
	// 1 error_string
	lua_getglobal(L, "debug"); // err debug
	lua_getfield(L, -1, "traceback"); // err debug traceback
	lua_pushvalue(L, -3); // err debug traceback err
	lua_call(L, 1, 1); // traceback(err), err debug tace
	CCLog("%s", lua_tostring(L, -1));
	lua_pop(L, 3); // empty
	return 0;
}

static int cclua_loadfile(lua_State* L, const string& file)
{
	string filename(file);
	bool isXml = false;
	size_t pos = filename.rfind('.');
	if (pos == string::npos)
	{
		string newFileName = filename + ".lua";
		if (oSharedContent.isFileExist(newFileName.c_str()))
		{
			filename = std::move(newFileName);
		}
		else
		{
			newFileName = filename + ".xml";
			if (oSharedContent.isFileExist(newFileName.c_str()))
			{
				filename = std::move(newFileName);
				isXml = true;
			}
			else
			{
				lua_pushnil(L);
				lua_pushliteral(L, "Xml and Lua files not found");
				return 2;
			}
		}
	}
	else
	{
		string extension = oString::toLower(filename.substr(pos + 1));
		isXml = extension == "xml";
	}

	unsigned long codeBufferSize = 0;
	oOwnArray<char> buffer;
	const char* codeBuffer = nullptr;
	string codes;
	if (isXml)
	{
		codes = oSharedXMLLoader.load(filename.c_str());
		if (codes.empty())
		{
			luaL_error(L, "error parsing xml file: %s\n%s", filename.c_str(), oSharedXMLLoader.getLastError().c_str());
		}
		else
		{
			codeBuffer = codes.c_str();
			codeBufferSize = codes.size();
		}
	}
	else
	{
		buffer = oSharedContent.loadFile(filename.c_str(), codeBufferSize);
		codeBuffer = buffer;
	}
	if (codeBuffer)
	{
		if (luaL_loadbuffer(L, codeBuffer, codeBufferSize, filename.c_str()) != 0)
		{
			luaL_error(L, "error loading module %s from file %s :\n\t%s",
				lua_tostring(L, 1), filename.c_str(), lua_tostring(L, -1));
		}
	}
	else
	{
		luaL_error(L, "can not get file data of %s", filename.c_str());
	}
	return 1;

}

static int cclua_loadfile(lua_State* L)
{
	string filename(luaL_checkstring(L, 1));
	return cclua_loadfile(L, filename);
}

static int cclua_dofile(lua_State* L)
{
	string filename(luaL_checkstring(L, 1));
	cclua_loadfile(L, filename);
	if (lua_isnil(L, -2) && lua_isstring(L, -1))
	{
		luaL_error(L, lua_tostring(L, -1));
	}
	int top = lua_gettop(L) - 1;
	CCLuaEngine::call(L, 0, LUA_MULTRET);
	int newTop = lua_gettop(L);
	return newTop - top;
}

static int cclua_loader(lua_State* L)
{
	string filename(luaL_checkstring(L, 1));
	size_t pos = 0;
	while ((pos = filename.find('.', pos)) != string::npos)
	{
		filename[pos] = '/';
	}
	return cclua_loadfile(L, filename);
}

static int cclua_doXml(lua_State* L)
{
	string codes(luaL_checkstring(L, 1));
	codes = oSharedXMLLoader.load(codes);
	if (codes.empty())
	{
		luaL_error(L, "error parsing local xml\n");
	}
	if (luaL_loadbuffer(L, codes.c_str(), codes.size(), "xml") != 0)
	{
		CCLOG("%s", codes.c_str());
		luaL_error(L, "error loading module %s from file %s :\n\t%s",
			lua_tostring(L, 1), "xml", lua_tostring(L, -1));
	}
	int top = lua_gettop(L) - 1;
	CCLuaEngine::call(L, 0, LUA_MULTRET);
	int newTop = lua_gettop(L);
	return newTop - top;
}

static int cclua_xmlToLua(lua_State* L)
{
	string codes(luaL_checkstring(L, 1));
	codes = oSharedXMLLoader.load(codes);
	if (codes.empty())
	{
		luaL_error(L, oSharedXMLLoader.getLastError().c_str());
	}
	lua_pushlstring(L, codes.c_str(), codes.size());
	return 1;
}

static int cclua_ubox(lua_State* L)
{
	lua_rawgeti(L, LUA_REGISTRYINDEX, TOLUA_UBOX);// ubox
	return 1;
}

static int cclua_loadlibs(lua_State* L)
{
	const luaL_Reg lualibs[] = {
		{ "", luaopen_base },
		{ LUA_LOADLIBNAME, luaopen_package },
		{ LUA_TABLIBNAME, luaopen_table },
		{ LUA_IOLIBNAME, luaopen_io },
		{ LUA_OSLIBNAME, luaopen_os },
		{ LUA_STRLIBNAME, luaopen_string },
		{ LUA_MATHLIBNAME, luaopen_math },
		{ LUA_DBLIBNAME, luaopen_debug },
		{ NULL, NULL }
	};
	const luaL_Reg* lib = lualibs;
	for (; lib->func; lib++)
	{
		lua_pushcfunction(L, lib->func);
		lua_pushstring(L, lib->name);
		lua_call(L, 1, 0);
	}
	return 1;
}

CCLuaEngine::CCLuaEngine()
{
	L = luaL_newstate();
	cclua_loadlibs(L);
	luaopen_lpeg(L);
	toluafix_open(L);
	tolua_LuaBinding_open(L);

	// Register our version of the global "print" function
	const luaL_reg global_functions[] =
	{
		{ "print", cclua_print },
		{ "loadfile", cclua_loadfile },
		{ "dofile", cclua_dofile },
		{ "doXml", cclua_doXml },
		{ "xmlToLua", cclua_xmlToLua },
		{ "ubox", cclua_ubox },
		{ NULL, NULL }
	};
	luaL_register(L, "_G", global_functions);

	// add cocos2dx loader
	addLuaLoader(cclua_loader);

	tolua_beginmodule(L, 0);//stack: package.loaded
	tolua_beginmodule(L, "CCNode");
	tolua_function(L, "gslot", CCNode_gslot);
	tolua_function(L, "slot", CCNode_slot);
	tolua_function(L, "emit", CCNode_emit);
	tolua_function(L, "traverse", CCNode_traverse);
	tolua_function(L, "eachChild", CCNode_eachChild);
	tolua_endmodule(L);
	tolua_beginmodule(L, "CCDictionary");//stack: package.loaded CCDictionary
	tolua_variable(L, "randomObject", CCDictionary_randomObject, nullptr);
	tolua_function(L, "set", CCDictionary_set);
	tolua_function(L, "get", CCDictionary_get);
	tolua_function(L, "each", CCDictionary_each);
	tolua_endmodule(L);
	tolua_beginmodule(L, "CCArray");
	tolua_function(L, "each", CCArray_each);
	tolua_endmodule(L);
	tolua_beginmodule(L, "CCTextureCache");
	tolua_function(L, "loadAsync", CCTextureCache_loadAsync);
	tolua_endmodule(L);
	tolua_endmodule(L);

	tolua_LuaCode_open(L);

	lua_settop(L, 0); // clear stack
}

CCLuaEngine* CCLuaEngine::sharedEngine()
{
	static CCLuaEngine engine;
	return &engine;
}

void CCLuaEngine::addSearchPath(const char* path)
{
	lua_getglobal(L, "package");/* L: package */
	lua_getfield(L, -1, "path");/* get package.path, L: package path */
	const char* cur_path = lua_tostring(L, -1);
	lua_pushfstring(L, "%s;%s/?.lua", cur_path, path);/* L: package path newpath */
	lua_setfield(L, -3, "path");/* package.path = newpath, L: package path */
	lua_pop(L, 2);/* L: - */
}

void CCLuaEngine::addLuaLoader(lua_CFunction func)
{
	if (!func) return;
	// stack content after the invoking of the function
	// get loader table
	lua_getglobal(L, "package");/* L: package */
	lua_getfield(L, -1, "loaders");/* L: package, loaders */
	// insert loader into index 1
	lua_pushcfunction(L, func);/* L: package, loaders, func */
	for (int i = (int)lua_objlen(L, -2) + 1; i > 1; --i)
	{
		lua_rawgeti(L, -2, i - 1);/* L: package, loaders, func, function */
		// we call lua_rawgeti, so the loader table now is at -3
		lua_rawseti(L, -3, i);/* L: package, loaders, func */
	}
	lua_rawseti(L, -2, 1);/* L: package, loaders */
	// set loaders into package
	lua_setfield(L, -2, "loaders");/* L: package */
	lua_pop(L, 1);
}

void CCLuaEngine::removeScriptHandler(int nHandler)
{
	toluafix_remove_function_by_refid(L, nHandler);
}

void CCLuaEngine::removePeer(CCObject* object)
{
	if (object->isLuaRef())
	{
		int refid = object->getLuaRef();
		lua_rawgeti(L, LUA_REGISTRYINDEX, TOLUA_UBOX);// ubox
		lua_rawgeti(L, -1, refid);// ubox ud
		if (!lua_isnil(L, -1))
		{
			lua_pushvalue(L, TOLUA_NOPEER);// ubox ud nopeer
			lua_setfenv(L, -2);// ud<nopeer>, ubox ud
		}
		lua_pop(L, 2);// empty
	}
}

int CCLuaEngine::executeString(const char *codes)
{
	luaL_loadstring(L, codes);
	return CCLuaEngine::execute(L, 0);
}

int CCLuaEngine::executeScriptFile(const char* filename)
{
	lua_pushstring(L, filename);
	return cclua_dofile(L);
}

int CCLuaEngine::executeGlobalFunction(const char* functionName)
{
	lua_getglobal(L, functionName);/* query function by name, stack: function */
	if (!lua_isfunction(L, -1))
	{
		CCLOG("[LUA ERROR] name '%s' does not represent a Lua function", functionName);
		lua_pop(L, 1);
		return 0;
	}
	return CCLuaEngine::execute(L, 0);
}

int CCLuaEngine::executeFunction(int nHandler, int paramCount, CCObject* params[])
{
	for (int i = 0; i < paramCount; i++)
	{
		tolua_pushccobject(L, params[i]);
	}
	return CCLuaEngine::execute(L, nHandler, paramCount);
}

int CCLuaEngine::executeFunction(int nHandler, int paramCount, void* params[], int paramTypes[])
{
	for (int i = 0; i < paramCount; i++)
	{
		tolua_pushusertype(L, params[i], paramTypes[i]);
	}
	return CCLuaEngine::execute(L, nHandler, paramCount);
}

int CCLuaEngine::executeFunction(int nHandler, int paramCount)
{
	return CCLuaEngine::execute(L, nHandler, paramCount);
}

int CCLuaEngine::executeActionUpdate(int nHandler, void* param, int paramType, float deltaTime)
{
	if (!nHandler) return 0;
	tolua_pushusertype(L, param, paramType);
	lua_pushnumber(L, deltaTime);
	return CCLuaEngine::execute(L, nHandler, 2);
}

int CCLuaEngine::executeNodeEvent(CCNode* pNode, int nAction)
{
	const char* name = nullptr;
	switch (nAction)
	{
	case CCNode::Enter:
		name = oSlotList::Entering;
		break;
	case CCNode::EnterTransitionDidFinish:
		name = oSlotList::Entered;
		break;
	case CCNode::Exit:
		name = oSlotList::Exited;
		break;
	case CCNode::ExitTransitionDidStart:
		name = oSlotList::Exiting;
		break;
	case CCNode::Cleanup:
		name = oSlotList::Cleanup;
		break;
	default:
		break;
	}
	oSlotList* slotList = CCNode_tryGetSlotList(pNode, name);
	if (slotList)
	{
		oRef<oSlotList> ref(slotList);
		slotList->invoke(L);
	}
	return 0;
}

int CCLuaEngine::executeAppEvent(int nHandler, int eventType)
{
	if (!nHandler) return 0;
	lua_pushinteger(L, eventType);
	return CCLuaEngine::execute(L, nHandler, 1);
}

int CCLuaEngine::executeMenuItemEvent(int eventType, CCMenuItem* menuItem)
{
	const char* name = nullptr;
	switch (eventType)
	{
	case CCMenuItem::TapBegan:
		name = oSlotList::TapBegan;
		break;
	case CCMenuItem::TapEnded:
		name = oSlotList::TapEnded;
		break;
	case CCMenuItem::Tapped:
		name = oSlotList::Tapped;
		break;
	default:
		break;
	}
	oSlotList* slotList = CCNode_tryGetSlotList(menuItem, name);
	if (slotList)
	{
		oRef<oSlotList> ref(slotList);
		tolua_pushccobject(L, menuItem);
		slotList->invoke(L, 1);
	}
	return 0;
}

int CCLuaEngine::executeSchedule(int nHandler, float dt)
{
	if (!nHandler) return 0;
	lua_pushnumber(L, dt);
	return CCLuaEngine::execute(L, nHandler, 1);
}

int CCLuaEngine::executeLayerTouchEvent(CCLayer* layer, int eventType, CCTouch* touch)
{
	const char* name = nullptr;
	switch (eventType)
	{
	case CCTouch::Began:
		name = oSlotList::TouchBegan;
		break;
	case CCTouch::Moved:
		name = oSlotList::TouchMoved;
		break;
	case CCTouch::Ended:
		name = oSlotList::TouchEnded;
		break;
	case CCTouch::Cancelled:
		name = oSlotList::TouchCancelled;
		break;
	default:
		break;
	}
	oSlotList* slotList(CCNode_tryGetSlotList(layer, name));
	if (slotList)
	{
		oRef<oSlotList> ref(slotList);
		tolua_pushccobject(L, touch);
		return slotList->invoke(L, 1);
	}
	return 1;
}

int CCLuaEngine::executeLayerTouchesEvent(CCLayer* layer, int eventType, CCSet* touches)
{
	const char* name = nullptr;
	switch (eventType)
	{
	case CCTouch::Began:
		name = oSlotList::TouchBegan;
		break;
	case CCTouch::Moved:
		name = oSlotList::TouchMoved;
		break;
	case CCTouch::Ended:
		name = oSlotList::TouchEnded;
		break;
	case CCTouch::Cancelled:
		name = oSlotList::TouchCancelled;
		break;
	default:
		break;
	}
	oSlotList* slotList = CCNode_tryGetSlotList(layer, name);
	if (slotList)
	{
		oRef<oSlotList> ref(slotList);
		lua_createtable(L, touches->count(), 0);
		int i = 1;
		for (CCSetIterator it = touches->begin(); it != touches->end(); ++it)
		{
			CCTouch* touch = (CCTouch*)*it;
			tolua_pushccobject(L, touch);
			lua_rawseti(L, -2, i++);
		}
		return slotList->invoke(L, 1);
	}
	return 1;
}

int CCLuaEngine::executeLayerKeypadEvent(CCLayer* layer, int eventType)
{
	const char* name = nullptr;
	switch (eventType)
	{
	case CCKeypad::Menu:
		name = oSlotList::KeyMenu;
		break;
	case CCKeypad::Back:
		name = oSlotList::KeyBack;
		break;
	default:
		break;
	}
	oSlotList* slotList(CCNode_tryGetSlotList(layer, name));
	if (slotList)
	{
		oRef<oSlotList> ref(slotList);
		slotList->invoke(L);
	}
	return 0;
}

int CCLuaEngine::executeAccelerometerEvent(CCLayer* layer, CCAcceleration* accelerationValue)
{
	oSlotList* slotList(CCNode_tryGetSlotList(layer, oSlotList::Acceleration));
	if (slotList)
	{
		oRef<oSlotList> ref(slotList);
		lua_pushnumber(L, accelerationValue->x);
		lua_pushnumber(L, accelerationValue->y);
		lua_pushnumber(L, accelerationValue->z);
		lua_pushnumber(L, accelerationValue->timestamp);
		slotList->invoke(L, 4);
	}
	return 0;
}

int CCLuaEngine::executeApplicationEvent(int handler, int eventType)
{
	if (handler)
	{
		lua_pushinteger(L, eventType);
		return CCLuaEngine::execute(L, handler, 1);
	}
	return 0;
}

int CCLuaEngine::executeEvent(int nHandler, const char* pEventName, CCObject* pEventSource)
{
	lua_pushstring(L, pEventName);
	if (pEventSource) tolua_pushccobject(L, pEventSource);
	return CCLuaEngine::execute(L, nHandler, pEventSource ? 2 : 1);
}

bool CCLuaEngine::executeAssert(bool cond, const char *msg)
{
	if (g_callFromLua == 0) return false;
	lua_pushfstring(L, "ASSERT FAILED ON LUA EXECUTE: %s", msg ? msg : "unknown");
	lua_error(L);
	return true;
}

bool CCLuaEngine::scriptHandlerEqual(int nHandlerA, int nHandlerB)
{
	toluafix_get_function_by_refid(L, nHandlerA);
	toluafix_get_function_by_refid(L, nHandlerB);
	int result = lua_equal(L, -1, -2);
	lua_pop(L, 2);
	return result != 0;
}

int CCLuaEngine::call(lua_State* L, int paramCount, int returnCount)
{
#ifndef TOLUA_RELEASE
	int functionIndex = -(paramCount + 1);
	int top = lua_gettop(L);
	int traceIndex = MAX(functionIndex + top, 1);
	if (!lua_isfunction(L, functionIndex))
	{
		CCLOG("[LUA ERROR] value at stack [%d] is not function in CCLuaEngine::call", functionIndex);
		lua_pop(L, paramCount + 1); // remove function and arguments
		return 0;
	}

	lua_pushcfunction(L, cclua_traceback);// func args... traceback
	lua_insert(L, traceIndex);// traceback func args...

	++g_callFromLua;
	int error = lua_pcall(L, paramCount, returnCount, traceIndex);// traceback error ret
	--g_callFromLua;

	lua_remove(L, traceIndex);

	if (error)// traceback error
	{
		return 0;
	}
#else
	lua_call(L, paramCount, returnCount);
#endif
	return 1;
}

int CCLuaEngine::execute(lua_State* L, int numArgs)
{
	int ret = 0;
	int top = lua_gettop(L) - numArgs - 1;
	if (CCLuaEngine::call(L, numArgs, 1))
	{
		// get return value
		if (lua_isnumber(L, -1))// traceback ret
		{
			ret = (int)(lua_tointeger(L, -1));
		}
		else if (lua_isboolean(L, -1))
		{
			ret = lua_toboolean(L, -1);
		}
	}
	else ret = 1;
	lua_settop(L, top);// stack clear
	return ret;
}

int CCLuaEngine::execute(lua_State* L, int nHandler, int numArgs)
{
	toluafix_get_function_by_refid(L, nHandler);// args... func
	if (!lua_isfunction(L, -1))
	{
		CCLOG("[LUA ERROR] function refid '%d' does not reference a Lua function", nHandler);
		lua_pop(L, 1 + numArgs);
		return 1;
	}
	if (numArgs > 0) lua_insert(L, -(numArgs + 1));// func args...

	return CCLuaEngine::execute(L, numArgs);
}

int CCLuaEngine::invoke(lua_State* L, int nHandler, int numArgs, int numRets)
{
	toluafix_get_function_by_refid(L, nHandler);// args... func
	if (!lua_isfunction(L, -1))
	{
		CCLOG("[LUA ERROR] function refid '%d' does not reference a Lua function", nHandler);
		lua_pop(L, 1 + numArgs);
		return 0;
	}
	if (numArgs > 0) lua_insert(L, -(numArgs + 1));// func args...

	return CCLuaEngine::call(L, numArgs, numRets);
}

int CCLuaEngine::executeActionCreate(int nHandler)
{
	int handler = 0;
	CCLuaEngine::invoke(L, nHandler, 0, 1);
	int top = lua_gettop(L);
	if (lua_isfunction(L, top))
	{
		handler = toluafix_ref_function(L, top);
	}
	lua_settop(L, 0);
	return handler;
}

NS_CC_END
