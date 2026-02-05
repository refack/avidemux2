#include "ADM_default.h"
#include "ADM_ffQsvAV1.h"
#undef ADM_MINIMAL_UI_INTERFACE // we need the full UI
#include "DIA_factory.h"

extern "C"
{
    #include "libavutil/opt.h"
}

ffqsvav1_encoder QsvAV1Settings = QSV_AV1_CONF_DEFAULT;

ADM_ffQsvAV1Encoder::ADM_ffQsvAV1Encoder(ADM_coreVideoFilter *src,bool globalHeader) : ADM_coreVideoEncoderFFmpeg(src,NULL,globalHeader)
{
    ADM_info("(AV1 QSV) Creating.\n");
    frameIncrement=src->getInfo()->frameIncrement;
}

bool ADM_ffQsvAV1Encoder::configureContext(void)
{
    _context->bit_rate = -1;
    _context->rc_max_rate = -1;

#define SET_OPT(x,y) av_dict_set(&_options,x,y,0)

    switch(QsvAV1Settings.preset)
    {
        case QSV_AV1_PRESET_VERYFAST: SET_OPT("preset","veryfast"); break;
        case QSV_AV1_PRESET_FASTER:   SET_OPT("preset","faster"); break;
        case QSV_AV1_PRESET_FAST:     SET_OPT("preset","fast"); break;
        case QSV_AV1_PRESET_MEDIUM:   SET_OPT("preset","medium"); break;
        case QSV_AV1_PRESET_SLOW:     SET_OPT("preset","slow"); break;
        case QSV_AV1_PRESET_VERYSLOW: SET_OPT("preset","veryslow"); break;
        default: break;
    }

    _context->gop_size = QsvAV1Settings.gopsize;

    char buf[64];

    switch(QsvAV1Settings.rc_mode)
    {
        case QSV_AV1_RC_CQP:
             snprintf(buf,64,"%d",QsvAV1Settings.quality);
             SET_OPT("q",buf); // q:v equivalent? or just use -q ?
             // In QSV wrappers, sometimes -q is mapped to -global_quality.
             // Let's assume global_quality for now as it is more common in av_dict for ffmpeg.
             SET_OPT("global_quality",buf);
             break;
        case QSV_AV1_RC_CBR:
             _context->bit_rate = QsvAV1Settings.bitrate * 1000;
             _context->rc_max_rate = _context->bit_rate;
             break;
        case QSV_AV1_RC_VBR:
             _context->bit_rate = QsvAV1Settings.bitrate * 1000;
             _context->rc_max_rate = QsvAV1Settings.max_bitrate * 1000;
             break;
        case QSV_AV1_RC_ICQ:
             snprintf(buf,64,"%d",QsvAV1Settings.quality);
             SET_OPT("global_quality",buf);
             break;
    }

    if (QsvAV1Settings.lookahead)
    {
         SET_OPT("look_ahead", "1");
         snprintf(buf,64,"%d",QsvAV1Settings.lookahead);
         SET_OPT("look_ahead_depth", buf);
    }

    switch(QsvAV1Settings.profile)
    {
        case QSV_AV1_PROFILE_MAIN: SET_OPT("profile","main"); break;
        case QSV_AV1_PROFILE_HIGH: SET_OPT("profile","high"); break;
        case QSV_AV1_PROFILE_PRO:  SET_OPT("profile","pro"); break;
    }

    return true;
}

bool ADM_ffQsvAV1Encoder::setup(void)
{
    if(false== ADM_coreVideoEncoderFFmpeg::setupByName("av1_qsv"))
    {
        ADM_info("[ffMpeg] Setup failed\n");
        return false;
    }
    ADM_info("[ffMpeg] Setup ok\n");
    return true;
}

uint64_t ADM_ffQsvAV1Encoder::getEncoderDelay(void)
{
    return 0;
}

ADM_ffQsvAV1Encoder::~ADM_ffQsvAV1Encoder()
{
    ADM_info("[ffQsvAV1Encoder] Destroying.\n");
}

const char *ADM_ffQsvAV1Encoder::getFourcc(void)
{
    return "AV01";
}

bool ADM_ffQsvAV1Encoder::encode (ADMBitstream * out)
{
    int sz;
again:
    sz=0;
    if(false==preEncode())
    {
        sz=encodeWrapper(NULL,out);
        if (sz<= 0)
        {
            if(sz<0)
                ADM_info("[ffQsvAV1] Error %d encoding video\n",sz);
            return false;
        }
        ADM_info("[ffQsvAV1] Popping delayed bframes (%d)\n",sz);
        goto link;
    }

    sz=encodeWrapper(_frame,out);
    if(sz<0)
    {
        ADM_warning("[ffQsvAV1] Error %d encoding video\n",sz);
        return false;
    }

    if(sz==0) // no pic, probably pre filling, try again
        goto again;
link:
    return postEncode(out,sz);
}

bool ffQsvAV1Configure(void)
{
    diaMenuEntry meRcMode[]={
        {QSV_AV1_RC_CQP,QT_TRANSLATE_NOOP("ffQsvAV1","Constant QP"),NULL},
        {QSV_AV1_RC_CBR,QT_TRANSLATE_NOOP("ffQsvAV1","Constant Bitrate"),NULL},
        {QSV_AV1_RC_VBR,QT_TRANSLATE_NOOP("ffQsvAV1","Variable Bitrate"),NULL},
        {QSV_AV1_RC_ICQ,QT_TRANSLATE_NOOP("ffQsvAV1","Intelligent Constant Quality (ICQ)"),NULL}
    };

    diaMenuEntry mePreset[]={
        {QSV_AV1_PRESET_VERYFAST,QT_TRANSLATE_NOOP("ffQsvAV1","Very Fast"),NULL},
        {QSV_AV1_PRESET_FASTER,QT_TRANSLATE_NOOP("ffQsvAV1","Faster"),NULL},
        {QSV_AV1_PRESET_FAST,QT_TRANSLATE_NOOP("ffQsvAV1","Fast"),NULL},
        {QSV_AV1_PRESET_MEDIUM,QT_TRANSLATE_NOOP("ffQsvAV1","Medium"),NULL},
        {QSV_AV1_PRESET_SLOW,QT_TRANSLATE_NOOP("ffQsvAV1","Slow"),NULL},
        {QSV_AV1_PRESET_VERYSLOW,QT_TRANSLATE_NOOP("ffQsvAV1","Very Slow"),NULL}
    };

    diaMenuEntry meProfile[]={
        {QSV_AV1_PROFILE_MAIN,QT_TRANSLATE_NOOP("ffQsvAV1","Main"),NULL},
        {QSV_AV1_PROFILE_HIGH,QT_TRANSLATE_NOOP("ffQsvAV1","High"),NULL},
        {QSV_AV1_PROFILE_PRO,QT_TRANSLATE_NOOP("ffQsvAV1","Professional"),NULL}
    };

    ffqsvav1_encoder *conf=&QsvAV1Settings;

#define PX(x) &conf->x
#define MZ(x) sizeof(x)/sizeof(diaMenuEntry)

    diaElemMenu rcmode(PX(rc_mode),QT_TRANSLATE_NOOP("ffQsvAV1","RC Mode:"),MZ(meRcMode),meRcMode);
    diaElemMenu preset(PX(preset),QT_TRANSLATE_NOOP("ffQsvAV1","Preset:"),MZ(mePreset),mePreset);
    diaElemMenu profile(PX(profile),QT_TRANSLATE_NOOP("ffQsvAV1","Profile:"),MZ(meProfile),meProfile);

    diaElemUInteger quality(PX(quality),QT_TRANSLATE_NOOP("ffQsvAV1","Quality/QP:"),1,255);
    diaElemUInteger bitrate(PX(bitrate),QT_TRANSLATE_NOOP("ffQsvAV1","Bitrate (kbps):"),1,500000);
    diaElemUInteger maxBitrate(PX(max_bitrate),QT_TRANSLATE_NOOP("ffQsvAV1","Max Bitrate (kbps):"),1,500000);
    diaElemUInteger gopSize(PX(gopsize),QT_TRANSLATE_NOOP("ffQsvAV1","GOP Size:"),0,1000);
    diaElemUInteger lookAhead(PX(lookahead),QT_TRANSLATE_NOOP("ffQsvAV1","Lookahead Depth:"),0,100);

    diaElemFrame rateControl(QT_TRANSLATE_NOOP("ffQsvAV1","Rate Control"));
    diaElemFrame frameControl(QT_TRANSLATE_NOOP("ffQsvAV1","Frame Control"));

    rateControl.swallow(&rcmode);
    rateControl.swallow(&preset);
    rateControl.swallow(&profile);
    rateControl.swallow(&quality);
    rateControl.swallow(&bitrate);
    rateControl.swallow(&maxBitrate);

    rcmode.link(meRcMode,1,&quality); // CQP -> Quality/QP
    rcmode.link(meRcMode+1,1,&bitrate); // CBR -> Bitrate
    rcmode.link(meRcMode+2,1,&bitrate); // VBR -> Bitrate
    rcmode.link(meRcMode+2,1,&maxBitrate); // VBR -> MaxBitrate
    rcmode.link(meRcMode+3,1,&quality); // ICQ -> Quality

    frameControl.swallow(&gopSize);
    frameControl.swallow(&lookAhead);

    diaElem *basics[]={
        &rateControl,
        &frameControl
    };

#define NB_ELEM(x) sizeof(x)/sizeof(diaElem *)
    if(diaFactoryRun(QT_TRANSLATE_NOOP("ffQsvAV1","AV1 QSV Configuration"),NB_ELEM(basics),basics))
        return true;
    return false;
}
