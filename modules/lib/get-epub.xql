xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace epub="http://exist-db.org/xquery/epub" at "epub.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace util="http://exist-db.org/xquery/util";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml";

declare function local:epub-is-cached($id as xs:string) {
	util:log("info", "Checking cache for: " || $id),
	util:binary-doc-available("/db/apps/sarit-pm/resources/epubs/" || $id)
};

declare function local:epub-get-cached($id as xs:string) {
	util:binary-doc("/db/apps/sarit-pm/resources/epubs/" || $id)
};

declare function local:work2epub($id as xs:string, $work as element(), $lang as xs:string?) {
    let $root := $work/ancestor-or-self::tei:TEI
    let $config := $config:epub-config($root, $lang)
    let $oddName := replace($config:odd, "^([^/\.]+).*$", "$1")
    let $cssDefault := util:binary-to-string(util:binary-doc($config:output-root || "/" || $oddName || ".css"))
    let $cssEpub := util:binary-to-string(util:binary-doc($config:app-root || "/resources/css/epub.css"))
    let $css := $cssDefault || 
        "&#10;/* styles imported from epub.css */&#10;" || 
        $cssEpub
		return epub:generate-epub($config, $root, $css, $id)
};

let $id := request:get-parameter("id", "")
let $epub := replace($id, "xml$", "epub")

return
    (
		util:log("info", "Is " || $epub || " cached? " || local:epub-is-cached($epub)),
        response:set-header("Content-Disposition", concat("attachment; filename=", concat($epub, '.epub'))),
				(: to not ignore cache param here :)
				(: if (request:get-parameter("cache", "yes") = "yes" and local:epub-is-cached($epub)) :)
				if (local:epub-is-cached($epub))
				then
					response:stream-binary(
						 local:epub-get-cached($epub),
						 'application/epub',
					    $epub)
				else
		      response:stream-binary(
			        compression:zip( local:work2epub($id, pages:get-document($id)/tei:TEI, request:get-parameter("lang", ())), true() ),
				      'application/epub+zip',
					    $epub
        )
    )