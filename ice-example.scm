(import scheme)
(import (chicken format))
(import (chicken plist))
(import ice)
(import ice-router)
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

(define (error-404-page params req i o)
  (write-string-response o "Sorry, but i cannot find this page" #:code 404))

(define routes `((()             . ,index-page)
                (("ping")        . ,ping-page)
                (("hello" #:who) . ,hello-page)
                (POST . ((("post") . ,post-page-post)))
                (("post")        . ,post-page-any)
                (any             . ,error-404-page)))

(define (handler req i o)
  (ice-route routes req i o))

(define server (ice-make-server handler))

(define thr (ice-start-server server host: "0.0.0.0" port: 6789 backlog: 16))

(thread-join! thr)
