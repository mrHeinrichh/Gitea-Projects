#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*KiwiListener)(int result);

int KiwiInit(const char* appkey);

int KiwiInitWithListner(const char* appkey, KiwiListener callback);

int KiwiServerToLocal(const char* name, char* ip, int ip_len, char* port, int port_len);

int KiwiSendLog(int mtype, const char* data);

int KiwiOnNetworkOn();

#ifdef __cplusplus
}
#endif
