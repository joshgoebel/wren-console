#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <uv.h>
#include "../cli/vm.h"
#include "scheduler.h"
#include "wren_vm.h"
#include "socket.h"

uv_loop_t *loop;
struct sockaddr_in addr;

/* utilities */

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

// void echo_write(uv_write_t *req, int status) {
//     if (status) {
//         fprintf(stderr, "Write error %s\n", uv_strerror(status));
//     }
//     free(req);
// }

void echo_read(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) {
  // fprintf(stderr, "incomiing data (nread: %d)", nread);
  WrenVM* vm = getVM();

    if (nread < 0) {
        if (nread != UV_EOF) {
            fprintf(stderr, "Read error %s\n", uv_err_name(nread));
            uv_close((uv_handle_t*) client, NULL);
        }
        uv_connection_t* c = client->data;
        if (nread == UV_EOF) {
          wrenEnsureSlots(vm,2);
          wrenSetSlotHandle(vm,0,c->delegate); // our delegate
          wrenSetSlotNull(vm,1);
          wrenDispatch(vm, "dataReceived(_)");
        }
    } else if (nread > 0) {
        // uv_write_t *req = (uv_write_t *) malloc(sizeof(uv_write_t));
        // uv_buf_t wrbuf = uv_buf_init(buf->base, nread);
        // uv_write(req, client, &wrbuf, 1, echo_write);

        uv_connection_t* c = client->data;

        
        wrenEnsureSlots(vm,2);
        wrenSetSlotHandle(vm,0,c->delegate); // our delegate
        wrenSetSlotBytes(vm,1,buf->base, nread);
        wrenDispatch(vm, "dataReceived(_)");
    }

    if (buf->base) {
        free(buf->base);
    }
}

/* UVServer */

void uvServerAccept(WrenVM* vm) {
  uv_server_t *server = wrenGetSlotForeign(vm, 0);

  uv_connection_t *conn = (uv_connection_t*)wrenGetSlotForeign(vm, 1);
  uv_tcp_init(getLoop(), (uv_tcp_t*)conn->handle); 

  if (uv_accept((uv_stream_t*)&server->server, (uv_stream_t*) conn->handle) == 0) {
    wrenSetSlotBool(vm, 0, true);
    conn->handle->data = conn;
  } else {
    wrenSetSlotBool(vm, 0, false);
  }
}

static void after_close(uv_handle_t* handle) {
    // fprintf(stderr, "after close\n");
}

void uvServerStop(WrenVM* vm) {
    // fprintf(stderr, "tcpServerStop\n");
    uv_server_t *server = wrenGetSlotForeign(vm, 0);
    uv_shutdown_t* req;
    // fprintf(stderr, "trying shutdown");
    // int r = uv_shutdown(req, (uv_stream_t*)&tcpServer->server, after_shutdown);

    uv_close((uv_handle_t*)&server->server, after_close);
}

void uvServerListen(WrenVM* vm) {
    uv_server_t *tcpServer = wrenGetSlotForeign(vm, 0);
    uv_tcp_init(getLoop(), &tcpServer->server);
    uv_tcp_bind(&tcpServer->server, (const struct sockaddr*)&tcpServer->addr, 0);

    int r = uv_listen((uv_stream_t*)&tcpServer->server, 128, on_new_connection);
    if (r) {
        fprintf(stderr, "Listen error %s\n", uv_strerror(r));
        // return 1;
    }
}

void uvServerDelegateSet(WrenVM* vm) {
    uv_server_t *server = (uv_server_t*)wrenGetSlotForeign(vm, 0);
    server->delegate = wrenGetSlotHandle(vm, 1);
}

void uvServerAllocate(WrenVM* vm) {
    // fprintf(stdout, "tcpServerAllocate\n");
    // fflush(0);

    uv_server_t* uvServer = (uv_server_t*)wrenSetSlotNewForeign(vm, 0, 0, sizeof(uv_server_t));

    const char* address = wrenGetSlotString(vm, 1);
    const double port = wrenGetSlotDouble(vm, 2);
    uvServer->server.data = uvServer;

    // fprintf(stderr, "addrss %s\n", address);
    // fprintf(stderr, "port %d\n", (int)port);

    uv_ip4_addr(address, port, &uvServer->addr);
}

void uvServerFinalize(void* data) {
    // fprintf(stdout, "tcpServerFinalize\n");
    // fflush(0);
    uv_server_t* server = (uv_server_t*) data;
    if (server->delegate) {
      wrenReleaseHandle(getVM(), server->delegate);
      server->delegate = NULL;
    }
}

void on_new_connection(uv_stream_t *server, int status) {
    if (status < 0) {
        fprintf(stderr, "New connection error %s\n", uv_strerror(status));
        return;
    }

    WrenVM* vm = getVM();
    uv_server_t *tcpServer = server->data;

    wrenEnsureSlots(vm,1);
    wrenSetSlotHandle(vm, 0, tcpServer->delegate);
    wrenDispatch(vm, "newIncomingConnection()");
}

void uvConnectionDelegateSet(WrenVM* vm) {
    uv_connection_t *conn = (uv_connection_t*)wrenGetSlotForeign(vm, 0);
    conn->delegate = wrenGetSlotHandle(vm, 1);
    uv_read_start((uv_stream_t*)conn->handle, alloc_buffer, echo_read);
}

void uvConnectionAllocate(WrenVM* vm) {
    // fprintf(stderr,"uvConnectionAllocate\n");
    uv_connection_t *conn = (uv_connection_t*)wrenSetSlotNewForeign(vm, 0, 0, sizeof(uv_connection_t));
    conn->handle = malloc(sizeof(uv_tcp_t));
    memset(conn->handle, 0, sizeof(uv_tcp_t));
}

WrenHandle* wrenCurrentFiber(WrenVM* vm) {
  return wrenMakeHandle(vm, OBJ_VAL(vm->fiber));
}

void do_connect(uv_connect_t *req, int status) {
  if (status!=0) {
    fprintf(stderr,"uv_tcp_connect failed %d\n", status);
    return;
  }

  WrenVM* vm = getVM();
  wrenEnsureSlots(vm,3);
  wrenGetVariable(vm, "socket", "UVConnection", 0);
  uv_connection_t *conn = (uv_connection_t*)wrenSetSlotNewForeign(vm, 2, 0, sizeof(uv_connection_t));

  conn->handle = req->handle;
  conn->handle->data = conn;

  WrenHandle* fiber = (WrenHandle*)req->data;
  free(req);
  wrenSetSlotHandle(vm, 1, fiber);
  schedulerResume(fiber, true);
  schedulerFinishResume();
}

void uvConnectionConnect(WrenVM* vm) {
  uv_tcp_t* socket = malloc(sizeof(uv_tcp_t));
  uv_tcp_init(getLoop(), socket);

  uv_connect_t* req = malloc(sizeof(uv_connect_t));
  req->data = wrenCurrentFiber(vm);

  const char* address = wrenGetSlotString(vm, 1);
  int port = wrenGetSlotDouble(vm, 2);

  struct sockaddr_in dest;
  uv_ip4_addr(address, port, &dest);
  uv_tcp_connect(req, socket, (const struct sockaddr*) &dest, do_connect);
}

void uvConnectionFinalize(void* data) {
  uv_connection_t *conn = (uv_connection_t *)data;
  if (conn->delegate) {
    wrenReleaseHandle(getVM(), conn->delegate);
    conn->delegate = NULL;
  }
  free(conn->handle);
}

void write_done(uv_write_t *req, int status) {
    if (status) {
        fprintf(stderr, "Write error %s\n", uv_strerror(status));
    }
    free(req->bufs);
    free(req);
}

void uvConnectionWriteBytes(WrenVM* vm) {
    uv_connection_t *conn = (uv_connection_t*)wrenGetSlotForeign(vm, 0);
    int dataSize;
    const char *data = wrenGetSlotBytes(vm,1,&dataSize);
    uv_write_t *req = (uv_write_t *) malloc(sizeof(uv_write_t));
    const char *dataCopy = malloc(dataSize);
    memcpy((void*)dataCopy, data, dataSize);
    uv_buf_t wrbuf = uv_buf_init((char*)dataCopy, dataSize);
    uv_write(req, conn->handle, &wrbuf, 1, write_done);
}

void uvConnectionWrite(WrenVM* vm) {
    uv_connection_t *conn = (uv_connection_t*)wrenGetSlotForeign(vm, 0);
    const char *text = wrenGetSlotString(vm,1);
    uv_write_t *req = (uv_write_t *) malloc(sizeof(uv_write_t));
    int dataSize = strlen(text);
    const char *textCopy = malloc(dataSize);
    memcpy((void*)textCopy, text, dataSize);
    uv_buf_t wrbuf = uv_buf_init((char*)textCopy, dataSize);
    uv_write(req, conn->handle, &wrbuf, 1, write_done);
}

void uvConnectionClose(WrenVM* vm) {
    uv_connection_t *conn = (uv_connection_t*)wrenGetSlotForeign(vm, 0);
    uv_read_stop((uv_stream_t*)conn->handle);
    uv_close((uv_handle_t*) conn->handle, NULL);
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
