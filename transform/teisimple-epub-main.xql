import module namespace m='http://www.tei-c.org/tei-simple/models/teisimple.odd/epub' at '/db/apps/sarit-pm/transform/teisimple-epub.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["../transform/teisimple.css"],
    "collection": "/db/apps/sarit-pm/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)