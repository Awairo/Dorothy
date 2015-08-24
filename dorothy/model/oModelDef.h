/* Copyright (c) 2013 Jin Li, http://www.luvfight.me

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#ifndef __DOROTHY_MODEL_OMEDOLDEF_H__
#define __DOROTHY_MODEL_OMEDOLDEF_H__

NS_DOROTHY_BEGIN

class oModelAnimationDef;
class oModel;
class oClipDef;

/** @brief It`s component class of oModelDef. Do not use it alone. */
class oSpriteDef
{
public:
	bool front;
	float x;
	float y;
	float rotation;
	float anchorX;
	float anchorY;
	float scaleX;
	float scaleY;
	float skewX;
	float skewY;
	float opacity;
	string name;
	string clip;

	oOwnVector<oSpriteDef> children;
	oOwnVector<oModelAnimationDef> animationDefs;
	vector<int> looks;

	oSpriteDef();
	void restore(CCSprite* sprite);
	/**
	 @brief get a new reset animation to restore a node before playing a new animation
	 returns an animation of CCSpawn with an array of
	 [oKeyPos,oKeyScale,oKeyRoll,oKeySkew,oKeyOpacity] instances that compose the CCSpawn instance.
	 or returns an animation of CCHide with nullptr.
	*/
	tuple<CCFiniteTimeAction*,CCArray*> toResetAction();
	CCSprite* toSprite(oClipDef* clipDef);
	string toXml();

	template<typename NodeFunc>
	static void traverse(oSpriteDef* root, const NodeFunc& func)
	{
		func(root);
		const oOwnVector<oSpriteDef>& childrenDef = root->children;
		for (oSpriteDef* childDef: childrenDef)
		{
			oSpriteDef::traverse(childDef, func);
		}
	}
};

/** @brief Data define for a 2D model. */
class oModelDef: public CCObject
{
public:
	oModelDef();
	oModelDef(
		bool isFaceRight,
		bool isBatchUsed,
		const CCSize& size,
		const string& clipFile,
		oSpriteDef* root,
		const unordered_map<string,oVec2>& keys,
		const unordered_map<string,int>& animationIndex,
		const unordered_map<string,int>& lookIndex);
	const string& getClipFile() const;
	oSpriteDef* getRoot();
	void addKeyPoint(const string& key, const oVec2& point);
	oVec2 getKeyPoint(const string& key) const;
	unordered_map<string,oVec2>& getKeyPoints();
	bool isFaceRight() const;
	bool isBatchUsed() const;
	const CCSize& getSize() const;
	void setActionName(int index, const string& name);
	void setLookName(int index, const string& name);
	int getAnimationIndexByName(const string& name);
	const char* getAnimationNameByIndex(int index);
	int getLookIndexByName(const string& name);
	const unordered_map<string, int>& getAnimationIndexMap() const;
	const unordered_map<string, int>& getLookIndexMap() const;
	vector<string> getLookNames() const;
	vector<string> getAnimationNames() const;
	string getTextureFile() const;
	oModel* toModel();
	string toXml();
	static oModelDef* create();
private:
	void setRoot(oSpriteDef* root);
	bool _isBatchUsed;
	bool _isFaceRight;
	CCSize _size;
	oOwn<oSpriteDef> _root;
	string _clip;
	unordered_map<string,int> _animationIndex;
	unordered_map<string,int> _lookIndex;
	unordered_map<string,oVec2> _keys;
	friend class oModelCache;
};

NS_DOROTHY_END

#endif // __DOROTHY_MODEL_OMEDOLDEF_H__