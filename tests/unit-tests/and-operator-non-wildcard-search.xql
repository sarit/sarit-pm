xquery version "3.0";

import module namespace app = "http://www.tei-c.org/tei-simple/templates" at "../../modules/app.xql";
import module namespace sarit-slp1 = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $search-expression := "anyathā AND sati"
let $processed-search-expression := app:preprocess-query-string($search-expression)
let $expected-hits-number := 1
    
let $hits := doc("../resources/search/resources-for-testing-of-searching.xml")//tei:p[ft:query(., $processed-search-expression)]
let $actual-hits-number := count($hits)

let $status := if ($expected-hits-number = $actual-hits-number) then "passed" else "failed"

return
	<result status="{$status}" expected-hits-number="{$expected-hits-number}" actual-hits-number="{$actual-hits-number}" search-expression="{$search-expression}"> 
	    <hits>{$hits}</hits>
    	<processed-search-expression>{$processed-search-expression}</processed-search-expression>
	</result>
