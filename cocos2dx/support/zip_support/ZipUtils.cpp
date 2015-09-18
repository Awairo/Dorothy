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
#include <zlib.h>
#include <assert.h>
#include <stdlib.h>
#include <ctype.h>

#include "ZipUtils.h"
#include "ccMacros.h"
#include "platform/CCFileUtils.h"
#include "unzip.h"
#include <unordered_map>
#include <unordered_set>

NS_CC_BEGIN

static void str_tolower(std::string& out)
{
	for (size_t i = 0;i < out.size();i++)
	{
		out[i] = tolower(out[i]);
	}
}

// --------------------- ZipUtils ---------------------

// memory in iPhone is precious
// Should buffer factor be 1.5 instead of 2 ?
#define BUFFER_INC_FACTOR (2)

int ZipUtils::ccInflateMemoryWithHint(unsigned char *in, unsigned int inLength, unsigned char **out, unsigned int *outLength, unsigned int outLenghtHint)
{
    /* ret value */
    int err = Z_OK;

    int bufferSize = outLenghtHint;
    *out = new unsigned char[bufferSize];

    z_stream d_stream; /* decompression stream */    
    d_stream.zalloc = (alloc_func)0;
    d_stream.zfree = (free_func)0;
    d_stream.opaque = (voidpf)0;

    d_stream.next_in  = in;
    d_stream.avail_in = inLength;
    d_stream.next_out = *out;
    d_stream.avail_out = bufferSize;

    /* window size to hold 256k */
    if( (err = inflateInit2(&d_stream, 15 + 32)) != Z_OK )
        return err;

    for (;;) 
    {
        err = inflate(&d_stream, Z_NO_FLUSH);

        if (err == Z_STREAM_END)
        {
            break;
        }

        switch (err) 
        {
        case Z_NEED_DICT:
            err = Z_DATA_ERROR;
        case Z_DATA_ERROR:
        case Z_MEM_ERROR:
            inflateEnd(&d_stream);
            return err;
        }

        // not enough memory ?
        if (err != Z_STREAM_END) 
        {
            delete [] *out;
            *out = new unsigned char[bufferSize * BUFFER_INC_FACTOR];

            /* not enough memory, ouch */
            if (! *out ) 
            {
                CCLOG("cocos2d: ZipUtils: realloc failed");
                inflateEnd(&d_stream);
                return Z_MEM_ERROR;
            }

            d_stream.next_out = *out + bufferSize;
            d_stream.avail_out = bufferSize;
            bufferSize *= BUFFER_INC_FACTOR;
        }
    }

    *outLength = bufferSize - d_stream.avail_out;
    err = inflateEnd(&d_stream);
    return err;
}

int ZipUtils::ccInflateMemoryWithHint(unsigned char *in, unsigned int inLength, unsigned char **out, unsigned int outLengthHint)
{
    unsigned int outLength = 0;
    int err = ccInflateMemoryWithHint(in, inLength, out, &outLength, outLengthHint);

    if (err != Z_OK || *out == NULL) {
        if (err == Z_MEM_ERROR)
        {
            CCLOG("cocos2d: ZipUtils: Out of memory while decompressing map data!");
        } else 
        if (err == Z_VERSION_ERROR)
        {
            CCLOG("cocos2d: ZipUtils: Incompatible zlib version!");
        } else 
        if (err == Z_DATA_ERROR)
        {
            CCLOG("cocos2d: ZipUtils: Incorrect zlib compressed data!");
        }
        else
        {
            CCLOG("cocos2d: ZipUtils: Unknown error while decompressing map data!");
        }

        delete[] *out;
        *out = NULL;
        outLength = 0;
    }

    return outLength;
}

int ZipUtils::ccInflateMemory(unsigned char *in, unsigned int inLength, unsigned char **out)
{
    // 256k for hint
    return ccInflateMemoryWithHint(in, inLength, out, 256 * 1024);
}

int ZipUtils::ccInflateGZipFile(const char *path, unsigned char **out)
{
    int len;
    unsigned int offset = 0;

    CCAssert(out, "");
    CCAssert(&*out, "");

    gzFile inFile = gzopen(path, "rb");
    if (inFile == NULL)
	{
		CCLOG("cocos2d: ZipUtils: error open gzip file: %s", path);
        return -1;
    }

    /* 512k initial decompress buffer */
    unsigned int bufferSize = 512 * 1024;
    unsigned int totalBufferSize = bufferSize;

    *out = (unsigned char*)malloc(bufferSize);
    if (!out)
    {
        CCLOG("cocos2d: ZipUtils: out of memory");
        return -1;
    }

    for (;;)
	{
        len = gzread(inFile, *out + offset, bufferSize);
        if (len < 0) 
        {
            CCLOG("cocos2d: ZipUtils: error in gzread");
            free(*out);
            *out = NULL;
            return -1;
        }
        if (len == 0)
        {
            break;
        }

        offset += len;

        // finish reading the file
		if ((unsigned int)len < bufferSize)
        {
            break;
        }

        bufferSize *= BUFFER_INC_FACTOR;
        totalBufferSize += bufferSize;
		unsigned char* tmp = (unsigned char*)realloc(*out, totalBufferSize);

        if (!tmp)
        {
			CCLOG("cocos2d: ZipUtils: out of memory");
            free(*out);
			*out = NULL;
            return -1;
        }

        *out = tmp;
    }

    if (gzclose(inFile) != Z_OK)
    {
        CCLOG("cocos2d: ZipUtils: gzclose failed");
    }

    return offset;
}

int ZipUtils::ccInflateCCZFile(const char* path, unsigned char** out)
{
	 CCAssert(out, "");
     CCAssert(&*out, "");

     // load file into memory
     unsigned char* compressed = NULL;
    
     unsigned long fileLen = 0;
     compressed = CCFileUtils::sharedFileUtils()->getFileData(path, "rb", &fileLen);

     if(NULL == compressed || 0 == fileLen) 
     {
         CCLOG("cocos2d: Error loading CCZ compressed file");
         return -1;
     }

     struct CCZHeader* header = (struct CCZHeader*)compressed;

     // verify header
     if (header->sig[0] != 'C' || header->sig[1] != 'C' || header->sig[2] != 'Z' || header->sig[3] != '!')
     {
         CCLOG("cocos2d: Invalid CCZ file");
         delete [] compressed;
         return -1;
     }

     // verify header version
     unsigned int version = CC_SWAP_INT16_BIG_TO_HOST(header->version);
     if (version > 2)
     {
         CCLOG("cocos2d: Unsupported CCZ header format");
         delete [] compressed;
         return -1;
     }

     // verify compression format
     if (CC_SWAP_INT16_BIG_TO_HOST(header->compression_type) != CCZ_COMPRESSION_ZLIB)
     {
         CCLOG("cocos2d: CCZ Unsupported compression method");
         delete [] compressed;
         return -1;
     }

     unsigned int len = CC_SWAP_INT32_BIG_TO_HOST(header->len);

     *out = (unsigned char*)malloc(len);
     if (! *out)
     {
         CCLOG("cocos2d: CCZ: Failed to allocate memory for texture");
         delete [] compressed;
         return -1;
     }


     unsigned long destlen = len;
     unsigned long source = (unsigned long) compressed + sizeof(*header);
     int ret = uncompress(*out, &destlen, (Bytef*)source, fileLen - sizeof(*header) );

     delete [] compressed;

     if (ret != Z_OK)
     {
         CCLOG("cocos2d: CCZ: Failed to uncompress data");
         free( *out );
         *out = NULL;
         return -1;
     }

     return len;
}

// --------------------- ZipFile ---------------------
// from unzip.cpp
#define UNZ_MAXFILENAMEINZIP 256

struct ZipEntryInfo
{
    unz_file_pos pos;
    uLong uncompressed_size;
};

class ZipFilePrivate
{
public:
    unzFile zipFile;

    // std::unordered_map is faster if available on the platform
    typedef std::unordered_map<std::string, struct ZipEntryInfo> FileListContainer;
    FileListContainer fileList;
	std::unordered_set<std::string> folderList;
};

ZipFile::ZipFile(const std::string &zipFile, const std::string &filter)
    : m_data(new ZipFilePrivate)
{
    m_data->zipFile = unzOpen(zipFile.c_str());
    if (m_data->zipFile)
    {
        setFilter(filter);
    }
}

ZipFile::~ZipFile()
{
    if (m_data && m_data->zipFile)
    {
        unzClose(m_data->zipFile);
    }
    CC_SAFE_DELETE(m_data);
}

bool ZipFile::setFilter(const std::string& filterStr)
{
    bool ret = false;
    do
    {
        CC_BREAK_IF(!m_data);
        CC_BREAK_IF(!m_data->zipFile);

		std::string filter(filterStr);
		str_tolower(filter);

        // clear existing file list
        m_data->fileList.clear();
		m_data->folderList.clear();

        // UNZ_MAXFILENAMEINZIP + 1 - it is done so in unzLocateFile
        char szCurrentFileName[UNZ_MAXFILENAMEINZIP + 1];
        unz_file_info64 fileInfo;

        // go through all files and store position information about the required files
        int err = unzGoToFirstFile64(m_data->zipFile, &fileInfo,
                szCurrentFileName, sizeof(szCurrentFileName) - 1);
        while (err == UNZ_OK)
        {
            unz_file_pos posInfo;
            int posErr = unzGetFilePos(m_data->zipFile, &posInfo);
            if (posErr == UNZ_OK)
            {
                std::string currentFileName = szCurrentFileName;
				str_tolower(currentFileName);

				// cache info about filtered files only (like 'assets/')
                if (filter.empty()
                    || currentFileName.substr(0, filter.length()) == filter)
                {
                    ZipEntryInfo entry;
                    entry.pos = posInfo;
                    entry.uncompressed_size = (uLong)fileInfo.uncompressed_size;

                    m_data->fileList[currentFileName] = entry;
					size_t pos = currentFileName.rfind('/');
					while (pos != std::string::npos)
					{
						currentFileName = currentFileName.substr(0, pos);
						m_data->folderList.insert(currentFileName);
						pos = currentFileName.rfind('/');
					}
				}
            }
            // next file - also get the information about it
            err = unzGoToNextFile64(m_data->zipFile, &fileInfo,
                    szCurrentFileName, sizeof(szCurrentFileName) - 1);
        }
        ret = true;

    } while(false);

    return ret;
}

std::vector<std::string> ZipFile::getDirEntries(const std::string& path, bool isFolder)
{
	std::string searchName = path;
	str_tolower(searchName);

	char last = searchName[searchName.length() - 1];
	if (last == '/' || last == '\\')
	{
		searchName.erase(--searchName.end());
	}
	size_t pos = 0;
	while ((pos = searchName.find("\\", pos)) != std::string::npos)
	{
		searchName[pos] = '/';
	}
	std::vector<std::string> results;
	if (isFolder)
	{
		for (const auto& folder : m_data->folderList)
		{
			if (searchName == folder.substr(0, searchName.length()))
			{
				size_t pos = folder.find('/', searchName.length()+1);
				if (pos == std::string::npos)
				{
					if (searchName.length() < folder.length())
					{
						results.push_back(folder.substr(searchName.length()+1));
					}
				}
			}
		}
	}
	else
	{
		for (const auto& it : m_data->fileList)
		{
			const std::string& file = it.first;
			if (searchName == file.substr(0, searchName.length()))
			{
				size_t pos = file.find('/', searchName.length()+1);
				if (pos == std::string::npos)
				{
					if (searchName.length() < file.length())
					{
						results.push_back(file.substr(searchName.length()+1));
					}
				}
			}
		}
	}
	return std::move(results);
}

bool ZipFile::fileExists(const std::string& fileName) const
{
	bool ret = false;
	do
	{
		CC_BREAK_IF(!m_data);
		std::string file(fileName);
		str_tolower(file);

		ret = m_data->fileList.find(file) != m_data->fileList.end() || m_data->folderList.find(file) != m_data->folderList.end();
	}
	while (false);
	return ret;
}

bool ZipFile::isFolder(const std::string& pathStr) const
{
	std::string path(pathStr);
	str_tolower(path);
	return m_data->folderList.find(path) != m_data->folderList.end();
}

unsigned char* ZipFile::getFileData(const std::string& fileName, unsigned long* pSize)
{
    unsigned char* pBuffer = NULL;
    if (pSize)
    {
        *pSize = 0;
    }

    do
    {
        CC_BREAK_IF(!m_data->zipFile);
        CC_BREAK_IF(fileName.empty());
		
		std::string file(fileName);
		str_tolower(file);

        ZipFilePrivate::FileListContainer::const_iterator it = m_data->fileList.find(file);
        CC_BREAK_IF(it == m_data->fileList.end());

        ZipEntryInfo fileInfo = it->second;

        int nRet = unzGoToFilePos(m_data->zipFile, &fileInfo.pos);
        CC_BREAK_IF(UNZ_OK != nRet);

        nRet = unzOpenCurrentFile(m_data->zipFile);
        CC_BREAK_IF(UNZ_OK != nRet);

        pBuffer = new unsigned char[fileInfo.uncompressed_size];
        int CC_UNUSED nSize = unzReadCurrentFile(m_data->zipFile, pBuffer, (unsigned int)fileInfo.uncompressed_size);
        CCAssert(nSize == 0 || nSize == (int)fileInfo.uncompressed_size, "the file size is wrong");

        if (pSize)
        {
            *pSize = fileInfo.uncompressed_size;
        }
        unzCloseCurrentFile(m_data->zipFile);
    } while (0);

    return pBuffer;
}

NS_CC_END
