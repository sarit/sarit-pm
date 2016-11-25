xquery version "3.0";

import module namespace sarit-slp1 = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $search-string := translate(sarit-slp1:transcode("tatr?"), "[?]", "?")
let $expected-hits-number := 2

let $search-xml := <query><wildcard>{$search-string}</wildcard></query>
let $hits := doc("../resources/search/resources-for-testing-of-searching.xml")//tei:p[ft:query(., $search-xml)]
let $actual-hits-number := count($hits)

let $status := if ($expected-hits-number = $actual-hits-number) then "passed" else "failed"

return
	<result status="{$status}" expected-hits-number="{$expected-hits-number}" actual-hits-number="{$actual-hits-number}" search-string="{$search-string}"> 
		{
			$hits
		}
	</result>
