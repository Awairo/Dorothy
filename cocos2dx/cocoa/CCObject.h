/****************************************************************************
Copyright (c) 2010 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
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

#ifndef __CCOBJECT_H__
#define __CCOBJECT_H__

#include "platform/CCPlatformMacros.h"

NS_CC_BEGIN

class CCZone;
class CCObject;
class CCNode;
class CCEvent;

extern CC_DLL int g_luaType;

template <class T>
int CCLuaType()
{
	static int type = ++g_luaType;
	return type;
}

template <class T>
T* CCLuaCast(CCObject* obj)
{
	return (obj && obj->getLuaType() == CCLuaType<T>()) ? (T*)obj : nullptr;
}

#define CC_LUA_TYPE(type) \
public: virtual int getLuaType() const \
{ \
	return CCLuaType<type>(); \
}

class CC_DLL CCCopying
{
public:
    virtual CCObject* copyWithZone(CCZone* pZone);
};

class CCObject;
class CC_DLL CCWeak
{
public:
	CCWeak(CCObject* target): _refCount(1), target(target){}
	void release();
	void retain();
	CCObject* target;
private:
	int _refCount;
};

class CC_DLL CCObject : public CCCopying
{
public:
	CCObject();
	virtual ~CCObject();
	unsigned int getObjectId() const;
	unsigned int getLuaRef();
	void addLuaRef();
	void removeLuaRef();
	void release();
	void retain();
	CCObject* autorelease();
	CCObject* copy();
	bool isSingleReference();
	unsigned int getRetainCount();
	virtual bool isEqual(const CCObject* pObject);
	virtual void update(float dt);
	static unsigned int getObjectCount();
	static unsigned int getLuaRefCount();
	CCWeak* getWeakRef();
private:
	bool _isManaged;
	// object id, each object has unique one
	unsigned int _id;
	// count of references
	unsigned int _ref;
	// lua reference id
	unsigned int _luaRef;
	// weak ref object
	CCWeak* _weak;
	friend class CCAutoreleasePool;
	CC_LUA_TYPE(CCObject)
};

typedef void (CCObject::*SEL_SCHEDULE)(float);
typedef void (CCObject::*SEL_CallFunc)();
typedef void (CCObject::*SEL_CallFuncN)(CCNode*);
typedef void (CCObject::*SEL_CallFuncND)(CCNode*, void*);
typedef void (CCObject::*SEL_CallFuncO)(CCObject*);
typedef void (CCObject::*SEL_MenuHandler)(CCObject*);
typedef void (CCObject::*SEL_EventHandler)(CCEvent*);
typedef int (CCObject::*SEL_Compare)(CCObject*);

#define schedule_selector(_SELECTOR) (SEL_SCHEDULE)(&_SELECTOR)
#define callfunc_selector(_SELECTOR) (SEL_CallFunc)(&_SELECTOR)
#define callfuncN_selector(_SELECTOR) (SEL_CallFuncN)(&_SELECTOR)
#define callfuncND_selector(_SELECTOR) (SEL_CallFuncND)(&_SELECTOR)
#define callfuncO_selector(_SELECTOR) (SEL_CallFuncO)(&_SELECTOR)
#define menu_selector(_SELECTOR) (SEL_MenuHandler)(&_SELECTOR)
#define event_selector(_SELECTOR) (SEL_EventHandler)(&_SELECTOR)
#define compare_selector(_SELECTOR) (SEL_Compare)(&_SELECTOR)

// end of base_nodes group
/// @}

NS_CC_END

#endif // __CCOBJECT_H__
