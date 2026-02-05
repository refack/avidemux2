#include "ADM_default.h"
#include "ADM_ffQsvAV1.h"
#include "ADM_coreVideoEncoderInternal.h"
#include "ffQsvAV1_desc.cpp"
extern bool            ffQsvAV1Configure(void);
extern ffqsvav1_encoder QsvAV1Settings;

void resetConfigurationData()
{
	ffqsvav1_encoder defaultConf = QSV_AV1_CONF_DEFAULT;
	memcpy(&QsvAV1Settings, &defaultConf, sizeof(ffqsvav1_encoder));
}

static bool qsvCheckDll(const char *zwin64, const char *zwin32, const char *zlinux)
{
        const char *dll;
#ifdef _WIN32
        #ifdef _WIN64
            dll=zwin64;
        #else
            dll=zwin32;
        #endif
#else
        dll=zlinux;
#endif

        ADM_LibWrapper wrapper;
        bool r=wrapper.loadLibrary(dll);
        ADM_info("\t checking %s-> %d\n",dll,r);
        return r;
}

extern "C"
{
    static bool qsvEncProbe(void)
    {
        if(qsvCheckDll("libmfxhw64.dll","libmfxhw32.dll","libmfx.so")) return true;
        if(qsvCheckDll("libmfx64.dll","libmfx32.dll","libmfx.so.1")) return true;

        // Also check specifically for libvpl (OneVPL) which replaces MediaSDK for newer hardware (Arc, etc)
        if(qsvCheckDll("libvpl.dll","libvpl.dll","libvpl.so")) return true;

        return false;
    }
}

ADM_DECLARE_VIDEO_ENCODER_PREAMBLE(ADM_ffQsvAV1Encoder);

ADM_DECLARE_VIDEO_ENCODER_MAIN_EX("ffQsvAV1",
                               "Intel QSV AV1",
                               "Intel QuickSync AV1 Encoder",
                                ffQsvAV1Configure,
                                ADM_UI_ALL,
                                1,0,0,
                                ffqsvav1_encoder_param,
                                &QsvAV1Settings,NULL,NULL,
                                qsvEncProbe
);
