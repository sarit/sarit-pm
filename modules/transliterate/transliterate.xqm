xquery version "3.0";

module namespace transliterate = "http://sarit.indology.info/ns/transliterate";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function transliterate:get-content($div as element()) {
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
