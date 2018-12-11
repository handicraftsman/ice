(module ice-router
        (ice-route)
  (import scheme)
  (import (chicken base))
  (import (chicken io))
  (import (chicken plist))
  (import (chicken keyword))
  (import srfi-1)
  (import srfi-13)
  (import intarweb)
  (import uri-common)
  (import ice)
  
  (define (pattern-match pattern path params)
    (cond
     [(and (null-list? pattern) (null-list? path))
      params]
     [(and (not (null-list? pattern)) (not (null-list? path)))
      (cond
       [(keyword? (car pattern))
        (pattern-match (cdr pattern) (cdr path)
                       (cons (cons (car pattern) (car path))
                             params))]
       [(and (string? (car pattern)) (string= (car pattern) (car path)))
        (pattern-match (cdr pattern) (cdr path) params)]
       [#t #f])]
     [(and (null-list? pattern) (not (null-list? path)))
      (if (string= (car path) "")
          params
          #f)]
     [(and (not (null-list? pattern)) (null-list? path))
      #f]
     [#t #f]))
  
  (define (ice-route routes req i o)
    (if (null-list? routes)
        (let [(res (make-response port: o code: 404))]
          (write-response res)
          (finish-response-body res)
          (write-line "404 not found" o))
        (let* [(r (car routes))
               (pattern (car r))
               (handler (cdr r))
               (params  (pattern-match pattern (cdr (uri-path (request-uri req))) '()))]
          (if params
              (handler params req i o)
              (ice-route (cdr routes) req i o)))))
  
)
