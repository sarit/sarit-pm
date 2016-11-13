xquery version "3.0";

import module namespace sarit-slp1 = "http://hra.uni-heidelberg.de/ns/sarit-transliteration";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $search-string := translate(sarit-slp1:transcode("kāryak?raṇ"), "[?]", "?")
let $search-xml := <query><wildcard>{$search-string}</wildcard></query>
let $hits := doc("../resources/search/resources-for-testing-of-searching.xml")//tei:p[ft:query(., $search-xml)]

return
	<result hits-number="{count($hits)}" search-string="{$search-string}"> 
		{
			$hits
		}
	</result>
