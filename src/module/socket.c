#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <uv.h>
#include "../cli/vm.h"
#include "socket.h"

uv_loop_t *loop;
struct sockaddr_in addr;

static WrenHandle* ConnectionHandle;
static WrenHandle* newConnectionHandle;

WrenHandle* wrenInstantiate(WrenVM* vm, const char* module, const char* class, const char* fn) {
    wrenGetVariable(vm, module, class, 0);
    WrenHandle* h = wrenMakeCallHandle(vm, fn);
    wrenCall(vm, h);
    return wrenGetSlotHandle(vm,0);
}

void wrenDispatch(WrenVM* vm, const char* name) {
    WrenHandle *handle = wrenMakeCallHandle(vm, name);
    wrenCall(vm, handle);
    wrenReleaseHandle(vm, handle);
}


void alloc_buffer(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    buf->base = (char*)malloc(suggested_size);
    buf->len = suggested_size;
}

void echo_write(uv_write_t *req, int status) {
    if (status) {
        fprintf(stderr, "Write error %s\n", uv_strerror(status));
    }
    free(req);
}

void echo_read(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) {
    if (nread < 0) {
        if (nread != UV_EOF) {
            fprintf(stderr, "Read error %s\n", uv_err_name(nread));
            uv_close((uv_handle_t*) client, NULL);
        }
    } else if (nread > 0) {
        // uv_write_t *req = (uv_write_t *) malloc(sizeof(uv_write_t));
        // uv_buf_t wrbuf = uv_buf_init(buf->base, nread);
        // uv_write(req, client, &wrbuf, 1, echo_write);


        WrenVM* vm = getVM();
        wrenEnsureSlots(vm,2);
        wrenSetSlotHandle(vm,0,client->data); // connection
        wrenSetSlotBytes(vm,1,buf->base, nread);
        wrenDispatch(vm, "input_(_)");
    }

    if (buf->base) {
        free(buf->base);
    }
}

void uvConnectionAllocate(WrenVM* vm) {
    fprintf(stderr,"uvConnectionAllocate\n");
    uv_tcp_t *client = (uv_tcp_t*)wrenSetSlotNewForeign(vm, 0, 0, sizeof(uv_tcp_t));
}


WrenHandle* onConnect;

void on_new_connection(uv_stream_t *server, int status) {
    if (status < 0) {
        fprintf(stderr, "New connection error %s\n", uv_strerror(status));
        return;
    }

    WrenVM* vm = getVM();
    
    wrenEnsureSlots(vm, 1);
    WrenHandle *conn = wrenInstantiate(vm, "socket","Connection","new()");
    wrenDispatch(vm, "uv_");

    uv_tcp_t *client = (uv_tcp_t*)wrenGetSlotForeign(vm, 0);
    uv_tcp_init(getLoop(), client);
    client->data = conn;
    if (uv_accept(server, (uv_stream_t*) client) == 0) {

        wrenEnsureSlots(vm, 3);
        // server.onConnect
        wrenSetSlotHandle(vm, 0, server->data);
        wrenDispatch(vm, "onConnect");

        // onConnect(new_connection)
        wrenSetSlotHandle(vm, 1, conn);
        wrenDispatch(vm, "call(_)");

        uv_read_start((uv_stream_t*)client, alloc_buffer, echo_read);
    } else {
        uv_close((uv_handle_t*) client, NULL);
    }
}

void write_done(uv_write_t *req, int status) {
    if (status) {
        fprintf(stderr, "Write error %s\n", uv_strerror(status));
    }
    free(req);
}


void uvConnectionWrite(WrenVM* vm) {
    uv_stream_t *client = (uv_stream_t*)wrenGetSlotForeign(vm, 0);
    const char *text = wrenGetSlotString(vm,1);
    // do write
    uv_write_t *req = (uv_write_t *) malloc(sizeof(uv_write_t));
    uv_buf_t wrbuf = uv_buf_init((char*)text, strlen(text));
    uv_write(req, client, &wrbuf, 1, write_done);
}

void uvConnectionClose(WrenVM* vm) {
    uv_tcp_t *client = wrenGetSlotForeign(vm, 0);
    uv_close((uv_handle_t*) client, NULL);
    wrenReleaseHandle(vm, client->data); // release connection reference
}


void tcpServerAllocate(WrenVM* vm) {
    fprintf(stdout, "tcpServerAllocate\n");
    fflush(0);

    tcp_server_t* tcpServer = (tcp_server_t*)wrenSetSlotNewForeign(vm, 0, 0, sizeof(tcp_server_t));
    memset(tcpServer, 0, sizeof(tcp_server_t));

    const char* address = wrenGetSlotString(vm, 1);
    const double port = wrenGetSlotDouble(vm, 2);
    WrenHandle* handle = wrenGetSlotHandle(vm, 3);
    tcpServer->handle = handle;
    tcpServer->server.data = handle;

    fprintf(stderr, "addrss %s\n", address);
    fprintf(stderr, "port %d\n", (int)port);



    uv_ip4_addr(address, port, &tcpServer->addr);
}

void tcpServerFinalize(WrenVM* vm) {
    fprintf(stdout, "tcpServerFinalize\n");
    fflush(0);
}

static void after_shutdown(uv_shutdown_t* req, int status) {
  /*assert(status == 0);*/
  if (status < 0)
    fprintf(stderr, "err: %s\n", uv_strerror(status));
  fprintf(stderr, "shutdown");
//   data_cntr = 0;
//   uv_close((uv_handle_t*)req->handle, on_close);
  free(req);
}

static void after_close(uv_handle_t* handle) {
    fprintf(stderr, "after close\n");
}

void tcpServerStop(WrenVM* vm) {
    fprintf(stderr, "tcpServerStop\n");
    tcp_server_t* tcpServer = (tcp_server_t*)wrenGetSlotForeign(vm, 0);
    uv_shutdown_t* req;
    // fprintf(stderr, "trying shutdown");
    // int r = uv_shutdown(req, (uv_stream_t*)&tcpServer->server, after_shutdown);

    uv_close((uv_handle_t*)&tcpServer->server, after_close);
}

void tcpServerListen(WrenVM* vm) {
    tcp_server_t* tcpServer = (tcp_server_t*)wrenGetSlotForeign(vm, 0);
    uv_tcp_init(getLoop(), &tcpServer->server);
    uv_tcp_bind(&tcpServer->server, (const struct sockaddr*)&tcpServer->addr, 0);

    int r = uv_listen((uv_stream_t*)&tcpServer->server, 128, on_new_connection);
    if (r) {
        fprintf(stderr, "Listen error %s\n", uv_strerror(r));
        // return 1;
    }
}


// int mains() {
//     loop = uv_default_loop();

//     uv_tcp_t server;
//     uv_tcp_init(loop, &server);

//     uv_ip4_addr("0.0.0.0", 7000, &addr);

//     uv_tcp_bind(&server, (const struct sockaddr*)&addr, 0);
//     int r = uv_listen((uv_stream_t*)&server, 128, on_new_connection);
//     if (r) {
//         fprintf(stderr, "Listen error %s\n", uv_strerror(r));
//         return 1;
//     }
//     return uv_run(loop, UV_RUN_DEFAULT);
// }
