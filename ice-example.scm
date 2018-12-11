(import scheme)
(import ice)
(import intarweb)
(import srfi-18)

(define (handler req i o)
  (write-string-response o "Hello, World!"))

(define server (ice-make-server handler))

(define thr (ice-start-server server host: "0.0.0.0" port: 6789 backlog: 16))

(thread-join! thr)
