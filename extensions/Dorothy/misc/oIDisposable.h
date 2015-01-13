/* Copyright (c) 2013 Jin Li, http://www.luvfight.me

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#ifndef __DOROTHY_OIDISPOSABLE_H__
#define __DOROTHY_OIDISPOSABLE_H__

#include "Dorothy/const/oDefine.h"

NS_DOROTHY_BEGIN

class oIDisposable;
typedef Delegate<void (oIDisposable* item)> oDisposeHandler;

/** @brief Interface for disposable item. */
class oIDisposable
{
public:
	/** Implement the method to get the item disposed. */
	virtual bool dispose() = 0;
	/** Invoke the delegate when this item is disposing,
	 so others may know it`s being disposed through the delegate. */
	oDisposeHandler disposing;
};

NS_DOROTHY_END

#endif // __DOROTHY_OIDISPOSABLE_H__
