class CCTileMapAtlas: public CCNode
{
	void setTile(ccColor3B tile, oVec2 position);
	ccColor3B tileAt @ getTile(oVec2& pos);

	static CCTileMapAtlas* create(const char* tile, const char* mapFile, int tileWidth, int tileHeight);
};
