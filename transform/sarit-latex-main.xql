import module namespace m='http://www.tei-c.org/tei-simple/models/sarit.odd/latex' at '/db/apps/sarit-pm/transform/sarit-latex.xql';

declare variable $xml external;

declare variable $parameters external;

let $options := map {
    "styles": ["../transform/sarit.css"],
    "collection": "/db/apps/sarit-pm/transform",
    "parameters": if (exists($parameters)) then $parameters else map {}
}
return m:transform($options, $xml)