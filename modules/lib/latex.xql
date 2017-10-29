(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 :
 : @author Wolfgang Meier
 :)
xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "util.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "text";
declare option output:html-version "5.0";
declare option output:media-type "text/text";

declare variable $local:WORKING_DIR := system:get-exist-home() || "/webapp";

declare function local:pdf-is-cached($id as xs:string) {
	util:log("info", "Checking cache for: " || $id),
	util:binary-doc-available($config:app-root || "/resources/pdfs/" || $id)
};

declare function local:pdf-get-cached($id as xs:string) {
	util:binary-doc($config:app-root || "/resources/pdfs/" || $id)
};

let $id := request:get-parameter("id", ())
let $requested-pdf := replace($id, "xml$", "pdf")
let $source := request:get-parameter("source", ())

return (
		if (local:pdf-is-cached($requested-pdf))
		then
			response:stream-binary(local:pdf-get-cached($requested-pdf), "media-type=application/pdf", $requested-pdf)
    else if ($id) then
        let $xml := pages:get-document($id)/tei:TEI
        let $config := tpu:parse-pi(root($xml), ())
        let $file :=
            replace($id, "^.*?([^/]+)$", "$1")
        return
            if ($source) then
                string-join($pm-config:latex-transform($xml, map { "image-dir": config:get-repo-dir() || "/" || $config:data-root[1] || "/" }, $config?odd))
						else
                let $serialized := file:serialize-binary(
									(: get tex file :)
									util:string-to-binary(
										string-join($pm-config:latex-transform($xml, map { "image-dir": config:get-repo-dir() || "/" || $config:data-root[1] || "/" }, $config?odd))),
										$local:WORKING_DIR || "/" || $file || ".tex")
                let $options :=
                    <option>
                        <workingDir>{$local:WORKING_DIR}</workingDir>
                    </option>
                let $output :=
                    process:execute(
                        ( $config:tex-command($file) ), $options
                    )
                return
                    if ($output/@exitCode < 2) then
                        let $pdf := file:read-binary($local:WORKING_DIR || "/" || $file || ".pdf")
                        return
                            response:stream-binary($pdf, "media-type=application/pdf", $file || ".pdf")
                    else
                        $output
    else
        <p>No document specified</p>
)
