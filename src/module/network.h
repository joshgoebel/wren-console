#ifndef socket_h
#define socket_h

typedef struct tcp_server_t {
    struct sockaddr_in addr;
    uv_tcp_t server;
    WrenHandle* delegate;
} uv_server_t;

typedef struct {
  uv_stream_t* handle;
  WrenHandle* delegate;
} uv_connection_t;


void alloc_buffer(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) ;
void echo_write(uv_write_t *req, int status) ;
void echo_read(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) ;
void on_new_connection(uv_stream_t *server, int status) ;


#endif