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

#ifndef __CC_LUA_ENGINE_H__
#define __CC_LUA_ENGINE_H__

extern "C" {
#include "lua.h"
#include "tolua++.h"
#include "lualib.h"
#include "lauxlib.h"
#include "tolua_fix.h"
}

#include "cocos2d.h"

NS_CC_BEGIN

// Lua support for cocos2d-x
class CCLuaEngine : public CCScriptEngine
{
public:
	static CCLuaEngine* sharedEngine();

	lua_State* getState() { return L; }

	/**
	 @brief Add a path to find lua files in
	 @param path to be added to the Lua path
	 */
	virtual void addSearchPath(const char* path);
	/**
	 @brief Add lua loader, now it is used on android
	 */
	virtual void addLuaLoader(lua_CFunction func);
	/**
	 @brief Remove Lua function reference
	 */
	virtual void removeScriptHandler(int nHandler);

	virtual void removePeer(CCObject* object);
	/**
	 @brief Execute script code contained in the given string.
	 @param codes holding the valid script code that should be executed.
	 @return 0 if the string is excuted correctly.
	 @return other if the string is excuted wrongly.
	 */
	virtual int executeString(const char* codes);
	/**
	 @brief Execute a script file.
	 @param filename String object holding the filename of the script file that is to be executed
	 */
	virtual int executeScriptFile(const char* filename);
	/**
	 @brief Execute a scripted global function.
	 @brief The function should not take any parameters and should return an integer.
	 @param functionName String object holding the name of the function, in the global script environment, that is to be executed.
	 @return The integer value returned from the script function.
	 */
	virtual int executeGlobalFunction(const char* functionName);
	virtual int executeFunction(int nHandler, int paramCount, CCObject* params[]);
	virtual int executeFunction(int nHandler, int paramCount, void* params[], const char* paramNames[]);
	virtual int executeFunction(int nHandler, int paramCount = 0);
	int call(int paramCount, int returnCount);

	virtual int executeActionCreate(int nHandler);
	virtual int executeActionUpdate(int nHandler, void* param, const char* paramName, float deltaTime);
	virtual int executeNodeEvent(CCNode* pNode, int nAction);
	virtual int executeAppEvent(int nHandler, int eventType);
	virtual int executeMenuItemEvent(int eventType, CCMenuItem* pMenuItem);
	virtual int executeSchedule(int nHandler, float dt, CCNode* pNode = NULL);
	virtual int executeLayerTouchesEvent(CCLayer* pLayer, int eventType, CCSet* pTouches);
	virtual int executeLayerTouchEvent(CCLayer* pLayer, int eventType, CCTouch* pTouch);
	virtual int executeLayerKeypadEvent(CCLayer* pLayer, int eventType);
	virtual int executeAccelerometerEvent(CCLayer* pLayer, CCAcceleration* pAccelerationValue);
	virtual int executeApplicationEvent(int handler, int eventType);
	
	virtual int executeEvent(int nHandler, const char* pEventName, CCObject* pEventSource = NULL);
	virtual bool executeAssert(bool cond, const char *msg = NULL);
	virtual bool scriptHandlerEqual(int nHandlerA, int nHandlerB);
private:
	CCLuaEngine();
	int lua_invoke(int nHandler, int numArgs, int numRets);
	int lua_execute(int numArgs);
	int lua_execute(int nHandler, int numArgs);
	lua_State* L;
	int m_callFromLua;
};

NS_CC_END

#endif // __CC_LUA_ENGINE_H__
