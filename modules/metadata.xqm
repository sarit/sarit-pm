xquery version "3.0";

module namespace metadata = "http://exist-db.org/ns/sarit/metadata/";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace app = "http://www.tei-c.org/tei-simple/templates" at "app.xql";
import module "http://expath.org/ns/pdf";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $metadata:metadata := doc($config:remote-root || "/metadata.xml")/*;

declare function metadata:count-pdf-pages() {
    let $pdf-files-collection := $config:remote-root || "/download/pdf/"
    let $pdf-work-pages :=
        for $pdf-file-name in xmldb:get-child-resources($pdf-files-collection)
        let $pdf-file-path := $pdf-files-collection || $pdf-file-name
        
        return map:get(pdf:get-metadata(util:binary-doc($pdf-file-path)), "number-of-pages")
        
    let $pdf-work-pages-total := sum($pdf-work-pages)
    
    let $store-pdf-work-pages-total := update value $metadata:metadata/metadata:number-of-pdf-pages with $pdf-work-pages-total

    
    return $pdf-work-pages-total
};

declare function metadata:get-relevant-xml-works() {
    collection($config:data-root)/tei:TEI
};

declare function metadata:count-relevant-xml-works() {
    let $number-of-relevant-xml-works := count(metadata:get-relevant-xml-works())
    let $store-number-of-relevant-xml-works := update value $metadata:metadata/metadata:number-of-xml-works with $number-of-relevant-xml-works
    
    return $number-of-relevant-xml-works
};

declare function metadata:get-size-of-relevant-xml-works() {
    let $works := metadata:get-relevant-xml-works()
    let $work-sizes :=
        for $work in $works
        return xmldb:size($config:data-root, util:document-name($work))
    let $total-works-size := sum($work-sizes)
    let $total-works-size-literal :=
        if ($total-works-size > 1000000000)
        then round($total-works-size div 1000000000) || " GB"
        else
            if ($total-works-size > 1000000)
            then round($total-works-size div 1000000) || " MB"
            else
                if ($total-works-size > 1000)
                then round($total-works-size div 1000) || " KB"
                else $total-works-size || " B"
    let $store-size-of-relevant-xml-works := update value $metadata:metadata/metadata:size-of-xml-works with $total-works-size-literal
    
    return $total-works-size-literal
};
