(module ice
        (ice-server
         ice-make-server
         ice-start-server
         write-string-response)
  (import scheme)
  (import (chicken base))
  (import (chicken io))
  (import (chicken condition))
  (import tcp6)
  (import intarweb)
  (import srfi-18)
  (import defstruct)
  
  (defstruct ice-server
    socket
    handler)

  (define (initial-handler i o h)
    
    (condition-case           
     (h (read-request i) i o) 
     [var () (print-error-message var) (print-call-chain)])

    (close-input-port i)
    (close-output-port o))
  
  (define (acceptor server)
    (define-values (i o) (tcp-accept (ice-server-socket server)))
    (thread-start! (make-thread (lambda ()
                                  (initial-handler i o (ice-server-handler server)))))
    (acceptor server))
  
  (define (ice-make-server handler)
    (make-ice-server acceptor: #f
                     handler: handler))

  (define (ice-start-server server #!key [host "0.0.0.0"] [port 6789] [backlog 16])
    (ice-server-socket-set! server
                            (tcp-listen port backlog host))
    (define thr
      (make-thread (lambda ()
                     (acceptor server))))
    (thread-start! thr)
    thr)

  (define (write-string-response o str)
    (define res (make-response port: o))
    (write-response res)
    (finish-response-body res)
    (write-line str o))
  
)
