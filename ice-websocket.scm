(module ice-websocket
        (wants-websocket?
         get-websocket-key
         with-websocket)
  (import scheme)
  (import (chicken base))
  (import (chicken foreign))
  (import ice)
  (import intarweb)
  (import srfi-1)
  (import srfi-13)
  (import sequences)
  (import message-digest-byte-vector)
  (import simple-sha1)
  (import base64)

  (foreign-declare "#include <openssl/sha.h>")
  
  (define (wants-websocket? req)
    (define h (request-headers req))
    (define connection (header-values 'connection h))
    (if (and
           (list? connection)
           (not (null-list? connection))
           (symbol? (car connection))
           (string= (symbol->string (car connection)) "upgrade"))
        (let [(upgrade (header-values 'upgrade h))]
          (if (and
               (list? upgrade)
               (not (null-list? upgrade))
               (string= (car (elt upgrade 0)) "websocket"))
              #t
              #f))
        #f))

  (define (get-websocket-key req)
    (define h (request-headers req))
    (define ikey (elt (header-values 'sec-websocket-key h) 0))
    (print ikey)
    ;; (define okey
    ;;   (base64-encode
    ;;    (string->sha1sum
    ;;     (string-append ikey ""))))
    (define okey-getter
      (foreign-lambda* c-string ((c-string magic) (c-string ikey)) "
       char* out;
       size_t il = strlen(ikey);
       size_t ml = strlen(magic);
       size_t tl = il + ml;
       char* in = malloc(tl + 1);
       strcpy(in, ikey);
       strcpy(in+il, magic);
       in[tl] = '\\0';
       char sd[SHA_DIGEST_LENGTH];
       SHA1(in, tl, sd);
       C_return(sd);
       "))
    (define okey (base64-encode (okey-getter "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" ikey)))
    okey)

  (define (with-websocket req i o #!key [with (lambda () #f)] [without (lambda () #f)])
    (if (wants-websocket? req)
        (let [(okey (get-websocket-key req)) (res (make-response port: o
                                                                 code: 101
                                                                 reason: "Web Socket Protocol Handshake"))]
          (print okey)
          (set-default-headers res)
          (push-header `(|Upgrade| #("websocket" raw)) res)
          (push-header `(|Connection| #("Upgrade" raw)) res)
          (push-header `(|Sec-WebSocket-Accept| #(,okey raw)) res)
          (write-response res)
          (finish-response-body res)
          (with))
        (without)))

)
