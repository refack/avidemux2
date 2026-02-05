	INCLUDE(ad_plugin)
	
	SET(ADM_ad_ulaw_SRCS ADM_ad_ulaw.cpp)

	ADM_ADD_AUDIO_DECODER_PLUGIN(ADM_ad_ulaw ${ADM_ad_ulaw_SRCS})
