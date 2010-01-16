! Copyright (C) 2010 Kat Marchán
! See http://factorcode.org/license.txt for BSD license.
USING: kernel stack-checker words compiler.units json.writer json.reader io arrays eval
namespaces sequences assocs ;

IN: facile

SYMBOL: quots
SYMBOL: config
SYMBOL: map-results

quots [ { } ] initialize

: respond ( response -- ) >json print flush ;

: emit ( array -- ) map-results swap [ prefix ] curry change ;

: (log) ( string -- response ) "Factor View Server: " prepend "log" swap 2array ;

: log ( string -- ) (log) respond ;

: add-quot ( string -- ) eval( -- quot ) quots [ swap prefix ] change-global t respond ;

: reset ( -- ) { } quots set t respond ;

: call-map-quot ( doc quot -- result )
    { } map-results
    [ call( doc -- ) map-results get ] with-variable ;

: (map-doc) ( doc -- results ) quots get-global swap [ swap call-map-quot ] curry map ;

: map-doc ( doc -- ) (map-doc) respond ;

: true-respond ( response -- ) t swap 2array respond ;

: split-kv ( keys-and-values -- values keys ) unzip swap keys ;

: (reduce-results) ( quot-strings keys-and-values -- reductions )
    split-kv rot f swap
    [ eval( -- quot ) call( values keys rereduce? -- reduction ) ]
    with with with map ;

: (rereduce) ( quot-strings values -- results )
    { } rot t swap
    [ eval( -- quot ) call( values keys rereduce? -- reduction ) ]
    with with with map ;

: (filter-docs) ( docs req user-context -- response ) 2drop ; ! todo

: reduce-results ( quot-strings keys-and-values -- ) (reduce-results) true-respond ;

: rereduce ( quot-strings values -- ) (rereduce) true-respond ;

: filter-docs ( docs req user-context -- ) (filter-docs) true-respond ;

: validate ( quot-string new-doc old-doc user-context -- ) 2drop 2drop ; ! todo

: show ( quot-string doc req -- ) 3drop ; ! todo

: update ( quot-string doc req -- ) 3drop ; ! todo

!
! View server
!
SYMBOL: dispatch-table
dispatch-table [
    {
        { "reset" [ reset ] }
        { "add_fun" [ add-quot ] }
        { "map_doc" [ map-doc ] }
        { "reduce" [ reduce-results ] }
        { "rereduce" [ rereduce ] }
        { "filter" [ filter-docs ] }
        { "validate" [ validate ] }
        { "show" [ show ] }
        { "update" [ update ] }
        ! { "list" [ couch-list ] }
    }
] initialize

: dispatch-command ( name -- quot ) dispatch-table get-global at ;

: next-line ( -- args cmd-name )
    readln dup empty?
    [ json> [ rest ] [ first ] bi swap ]
    [ drop next-line ]
    if ;

: run-server ( -- )
    [
        next-line dispatch-command call t
    ]
    loop ;

MAIN: run-server
