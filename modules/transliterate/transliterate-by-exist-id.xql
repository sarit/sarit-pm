xquery version "3.1";

import module namespace transliterate = "http://sarit.indology.info/ns/transliterate" at "transliterate.xqm";
import module namespace pages = "http://www.tei-c.org/tei-simple/pages" at "/apps/sarit-pm/modules/pages.xql";
import module namespace config = "http://www.tei-c.org/tei-simple/pages" at "/apps/sarit-pm/modules/config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $doc := "kautalyarthasastra.xml"
let $root := "1.5.6.3"
let $id := ""
let $view := "div"

let $xml :=
    if ($id)
    then
        let $node := doc($config:app-root || "/" || $doc)/id($id)
        let $div := $node/ancestor-or-self::tei:div[1]
        return
            if (empty($div)) then
                $node/following-sibling::tei:div[1]
            else
                $div
    else
        pages:load-xml($view, $root, $doc)
let $xml := transliterate:get-content($xml)

return $xml
