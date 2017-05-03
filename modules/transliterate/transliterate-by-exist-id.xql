xquery version "3.1";

import module namespace pages = "http://www.tei-c.org/tei-simple/pages" at "/apps/sarit-pm/modules/pages.xql";
import module namespace config = "http://www.tei-c.org/tei-simple/pages" at "/apps/sarit-pm/modules/config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function local:get-content($div as element()) {
    typeswitch ($div)
        case element(tei:teiHeader) return $div
(:        case element(tei:pb) return ( :)
(:            let $edition := pages:edition($div):)
(:            let $nextPage :=:)
(:                if ($edition) then:)
(:                    $div/following::tei:pb[@ed = $edition][1]:)
(:                else:)
(:                    $div/following::tei:pb[1]:)
(:            let $chunk :=:)
(:                pages:milestone-chunk($div, $nextPage,:)
(:                    if ($nextPage) then:)
(:                        ($div/ancestor::* intersect $nextPage/ancestor::*)[last()]:)
(:                    else:)
(:                        ($div/ancestor::tei:div, $div/ancestor::tei:body)[1]:)
(:                ):)
(:            return:)
(:                $chunk:)
(:        ) :)
        case element(tei:div) return
            if ($div/tei:div)
            then
                let $child := $div/tei:div[1]
                
                return
                        element { node-name($div) } {
                            $div/@*,
                            ($child/preceding-sibling::*, $child)
                        }
            else
                $div
        default return
            $div
};

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
let $xml := local:get-content($xml)

return $xml
