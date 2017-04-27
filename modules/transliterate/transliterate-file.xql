xquery version "3.1";

import module namespace sarit-slp1 = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function local:transcode-node($node) {
    element {QName("http://www.tei-c.org/ns/1.0", $node/local-name())} {
        $node/@*
        ,    
        for $child-node in $node/node()
        
        return
            if ($child-node instance of element())
            then local:transcode-node($child-node)
            else 
                if ($child-node instance of comment())
                then comment {$child-node}
                else sarit-slp1:transliterate($child-node, "deva", "roman")
     }
};

let $data-collection-path := "/apps/sarit-data/data/"
let $document-name := "mahabharata-devanagari"
let $document := doc($data-collection-path || $document-name || ".xml")

let $result-document-path := $data-collection-path || "temp/" || $document-name || "-iast.xml"
(: let $store-result-document := xmldb:store($result-document-path, $document-name || "-iast.xml", $document) :)
let $result-document := doc($result-document-path)

return
    for $node in $result-document//tei:text/tei:body/tei:div[12]/tei:div[position() = (242 to 243)]
    let $processed-node := local:transcode-node($node)
    
    return update replace $node with $processed-node

 (:
12 - 375
13 - 274
14 - 118
15 - 9
16 - 41
17 - 3
18 - 6
 tei:div[position() = (1 to 5)]
 (tei:head | tei:p)
 :)