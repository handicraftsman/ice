(import scheme)
(import (chicken format))
(import (chicken plist))
(import (chicken io))
(import ice)
(import ice-router)
(import ice-websocket)
(import intarweb)
(import srfi-18)

(define (index-page params req i o)
  (write-string-response o "Hello, World!"))

(define (ping-page params req i o)
  (write-string-response o "Pong!"))

(define (hello-page params req i o)
  (write-string-response o (format #f "Hello, ~A" (alist-ref #:who params))))

(define (post-page-post params req i o)
  (write-string-response o "You're cool!"))

(define (post-page-any params req i o)
  (write-string-response o "Please use POST"))

(define (ws-page params req i o)
  (define (w)
    (sleep 2)
    (print "asd"))
  (define (wo)
    (define res (make-response port: o))
    (set-default-headers res)
    (push-header `(|Content-Type| #("text/html" raw)) res)
    (write-response res)
    (finish-response-body res)
    (define s "<!DOCTYPE html>
<html>
  <head>
    <title>WebSocket test</title>
    <script>
      var s = new WebSocket(\"wss://new.hellomouse.net:8081/websocket\");
    </script>
  </head>
  <body>
    <p>WebSocket test</p>
  </body>
</html>")
    (write-string s (string-length s) o))
  (with-websocket req i o with: w without: wo))

(define (error-404-page params req i o)
  (write-string-response o "Sorry, but i cannot find this page" #:code 404))

(define routes `((()             . ,index-page)
                (("ping")        . ,ping-page)
                (("hello" #:who) . ,hello-page)
                (POST . ((("post") . ,post-page-post)))
                (("post")        . ,post-page-any)
                (("websocket")   . ,ws-page)
                (any             . ,error-404-page)))

(define (handler req i o)
  (ice-route routes req i o))

(define server (ice-make-server handler))

(define thr (ice-start-server server host: "0.0.0.0" port: 6789 backlog: 16))

(thread-join! thr)
