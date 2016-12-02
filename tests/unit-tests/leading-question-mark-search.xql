xquery version "3.0";

import module namespace app = "http://www.tei-c.org/tei-simple/templates" at "../../modules/app.xql";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $search-string := app:preprocess-query-string("?atra")
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
