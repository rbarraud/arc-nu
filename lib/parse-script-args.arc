(parameter script-arg-options     (obj))
(parameter script-arg-arguments   nil)
(parameter script-arg-groups      nil)
(parameter script-register-help?  t)

(def parse-arg (x)
  (aif (and (isnt x.1 #\-)
            (isnt len.x 2))
         (maplet c (cdr:coerce x 'cons)
           (let (h) (parse-arg:string "-" c)
             (if (is h!len 0)
                 h
                 (err:string "option \"-" c "\" cannot be used in the shorthand syntax \"" x "\""))))
       script-arg-options.x
         list.it
       (err "unknown option" x)))

(def parse-args (x)
  (awhenlet (x . rest) x
    (if (is x "--")
          rest
        (is x.0 #\-)
          (do (each h parse-arg.x
                (let (args r) (if (no h!len)
                                  (list rest nil)
                                  (split rest h!len))
                  (each y args
                    (when (is y.0 #\-)
                      (err:string "cannot pass argument \"" y "\" to argument \"" x "\"")))
                  (apply h!fn args)
                  (= rest r)))
              (self rest))
        (cons x self.rest))))

(mac register-script-arg args
  (awith (x     args
          opts  nil)
    (let c car.x
      (if (isa c 'string)
            (self cdr.x (cons c opts))
          opts
            (w/uniq u
              (with (help  (when (isa cadr.x 'string)
                             (zap cdr x)
                             car.x)
                     opts  rev.opts)
                `(let ,u (obj args  ',c
                              len   ,(and alist.c
                                          (no dotted.c)
                                          len.c)
                              help  ,help
                              fn    (fn ,c ,@cdr.x))
                   (push ',opts script-arg-groups)
                   ,@(maplet x opts
                       `(= (script-arg-options ,x) ,u)))))
          `(push ',x script-arg-arguments)))))

(def print-script-help ()
  (pr "Usage: ")
  (when script-arg-groups
    (pr "[<option> ...] "))
  (if script-arg-arguments
      (prn "<argument> ...")
      (prn "[<argument> ...]")
      ;(prn:string:intersperse " " (map car rev.it))
      )
  (prn)
  (when script-arg-groups
    (prn " <option>"))
  (each x rev.script-arg-groups
    (let h (script-arg-options car.x)
      (pr "  ")
      (awhenlet (x . rest) x
        (pr x)
        (when rest
          (pr ", ")
          (self rest)))
      (awhenlet x h!args
        (if acons.x
            (let c car.x
              (if (caris c 'o)
                  (let (_ n d) c
                    (pr " [<" n ">")
                    (when d (pr " " d))
                    (pr "]"))
                  (pr " <" c ">"))
              (self cdr.x))
            (pr " <" x "> ...")))
      (awhen h!help
        (pr " : " it)))
    (prn))
  (awhen script-arg-arguments
    (prn)
    (prn " <argument>")
    (each (n d) rev.it
      (pr "  " n)
       (when d (pr " : " d))
       (prn)))
  (quit))

(mac w/parse-args (x . args)
  `(w/script-arg-options %.hash-copy.script-arg-options
     (w/script-arg-groups script-arg-groups
       (w/script-arg-arguments script-arg-arguments
         (when script-register-help?
           (register-script-arg "-h" "--help" () "Displays this help message and exits"
             (print-script-help)))
         ,@(maplet x args
             `(register-script-arg ,@x))
         (parse-args ,x)))))

(mac parse-script-args args
  `(= script-args (w/parse-args script-args ,@args)))

#|

> (w/parse-args '("foo" "bar" "qux" "-v" "-x" "corge" "foobar")
    ("-v" (x) (prn x))
    ("-x"   y (prn y)))
error: cannot pass argument "-x" to argument "-v"


> (w/parse-args '("foo" "bar" "qux" "-vx" "corge" "foobar")
    ("-v" (x) (prn x))
    ("-x"  () (prn "bar")))
error: option "-v" cannot be used in the shorthand syntax "-vx"


> (w/parse-args '("foo" "bar" "qux" "-vx" "-n" "corge" "foobar")
    ("-v" () (prn "foo"))
    ("-x" () (prn "bar")))
error: unknown option "-n"


> (w/parse-args '("foo" "bar" "qux" "-vx" "--" "-n" "corge" "foobar")
    ("-v" () (prn "foo"))
    ("-x" () (prn "bar")))
foo
bar
("foo" "bar" "qux" "-n" "corge" "foobar")


> (w/parse-args '("foo" "bar" "qux" "-vx" "corge" "foobar")
    ("-v" () (prn "foo"))
    ("-x" () (prn "bar")))
("foo" "bar" "qux" "corge" "foobar")


> (w/parse-args '("foo" "bar" "qux" "-v" "-x" "corge" "foobar")
    ("-v" () (prn "foo"))
    ("-x"  y (prn y)))
foo
(corge foobar)
("foo" "bar" "qux")


> (w/parse-args '("-h")
    ("-v" ()                      "verbose" (prn "foo"))
    ("-f" (a b (o c 5) (o d) . e) "find"    (prn "yes"))
    ("-b" y                       "butt"    (prn "nou"))
    ("-x" (x . y)                 "nix"     (prn y)))
Usage: [<option> ...] [<argument> ...]
\
 <option>
  -h, --help : Displays this help message
  -v : verbose
  -f <a> <b> [<c> 5] [<d>] <e> ... : find
  -b <y> ... : butt
  -x <x> <y> ... : nix


> (w/parse-args '("-h")
    ("-v" ()                      "verbose" (prn "foo"))
    ("-f" (a b (o c 5) (o d) . e) "find"    (prn "yes"))
    ("-b" y                       "butt"    (prn "nou"))
    ("-x" (x . y)                 "nix"     (prn y))
    ((foo) "test")
    ((bar) "test2"))
Usage: [<option> ...] <argument> ...
\
 <option>
  -h, --help : Displays this help message
  -v : verbose
  -f <a> <b> [<c> 5] [<d>] <e> ... : find
  -b <y> ... : butt
  -x <x> <y> ... : nix
\
 <argument>
  foo : test
  bar : test2

|#
