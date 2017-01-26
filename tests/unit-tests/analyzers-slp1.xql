xquery version "3.0";

(: 

Test wildcard/boolean queries on Sanskrit texts in combination with an
SLP1 index.

See
https://wiki.apache.org/lucene-java/LuceneFAQ#Are_Wildcard.2C_Prefix.2C_and_Fuzzy_queries_case_sensitive.3F

To run, install app and then visit:
http://localhost:8080/exist/rest/db/apps/sarit-pm/tests/unit-tests/suite-slp1.xql

 :)

module namespace analyze="http://exist-db.org/xquery/lucene/test/analyzers";

import module namespace app = "http://www.tei-c.org/tei-simple/templates" at "../../modules/app.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(: the standard analyzer, should be case insensitive :)
declare variable $analyze:XCONF-CASEINS :=
    <collection xmlns="http://exist-db.org/collection-config/1.0">
        <index xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <lucene>
        <analyzer class="org.apache.lucene.analysis.core.StandardAnalyzer"/>
	<!-- parser makes no difference? -->
        <!-- <parser class="org.apache.lucene.analysis.core.StandardAnalyzer"/> -->
        <text qname="tei:p"/>
        </lucene>
        </index>
        <triggers>
            <trigger class="org.exist.extensions.exquery.restxq.impl.RestXqTrigger"/>
        </triggers>
    </collection>;


(: simple whitespace analyzer, should be case sensitive :)
declare variable $analyze:XCONF-CASESENS :=
    <collection xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://exist-db.org/collection-config/1.0">
        <index xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <lucene>
        <analyzer class="org.apache.lucene.analysis.core.WhitespaceAnalyzer"/>
	<!-- parser makes no difference? -->
        <!-- <parser class="org.apache.lucene.analysis.core.WhitespaceAnalyzer"/> -->
                <text qname="tei:p"/>
            </lucene>
        </index>
        <triggers>
            <trigger class="org.exist.extensions.exquery.restxq.impl.RestXqTrigger"/>
        </triggers>
    </collection>;

(: the standard analyzer, should be case insensitive :)
declare variable $analyze:XCONF-SLP1:=
    <collection xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://exist-db.org/collection-config/1.0">
        <index xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <lucene>
	<analyzer class="de.unihd.hra.libs.java.luceneTranscodingAnalyzer.TranscodingAnalyzer">
	  </analyzer>
        <text qname="tei:p"/>
        </lucene>
        </index>
        <triggers>
            <trigger class="org.exist.extensions.exquery.restxq.impl.RestXqTrigger"/>
        </triggers>
    </collection>;


(: setup testing environment :)

declare
    %test:setUp
function analyze:setup() {
	let $testCol := xmldb:create-collection("/db", "sarit-slp1-tests")
	let $testCol-CaseIns := xmldb:create-collection("/db/sarit-slp1-tests", "test1")
	let $testCol-CaseSens := xmldb:create-collection("/db/sarit-slp1-tests", "test2")
	let $testCol-SLP1 := xmldb:create-collection("/db/sarit-slp1-tests", "test3")
	let $confCol := xmldb:create-collection("/db/system/config/db", "sarit-slp1-tests")
	let $confCol-CaseIns := xmldb:create-collection("/db/system/config/db/sarit-slp1-tests", "test1")
	let $confCol-CaseSens := xmldb:create-collection("/db/system/config/db/sarit-slp1-tests", "test2")
	let $confCol-SLP1 := xmldb:create-collection("/db/system/config/db/sarit-slp1-tests", "test3")
	let $testdoc := doc("../resources/search/slp1-tests.xml")
    return (
        xmldb:store($confCol-CaseIns, "collection.xconf", $analyze:XCONF-CASEINS),
        xmldb:store($testCol-CaseIns, "test.xml", $testdoc),
        xmldb:store($confCol-CaseSens, "collection.xconf", $analyze:XCONF-CASESENS),
	xmldb:store($testCol-CaseSens, "test.xml", $testdoc),
	xmldb:store($confCol-SLP1, "collection.xconf", $analyze:XCONF-SLP1),
        xmldb:store($testCol-SLP1, "test.xml", $testdoc)
    )
};


(: clean up testing environment :)

declare
   %test:tearDown
function analyze:tearDown() {
   xmldb:remove("/db/sarit-slp1-tests"),
   xmldb:remove("/db/system/config/db/sarit-slp1-tests")
};



declare 
    %test:args("khalu")
    %test:assertEquals("biast")
    %test:args("eva")
    %test:assertEquals("ciast")
    %test:args("mutsārya")
    %test:assertEquals("diast")
    %test:args("खलु")
    %test:assertEquals("bdeva")

function analyze:case-insensitive-simple-term-query($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test1")//tei:p[ft:query(., $querystring)]/@xml:id/string()
};


declare
    %test:args("khal*")
    %test:assertEquals("biast")
    %test:args("e?a*")
    %test:assertEquals("aiast", "ciast")
    %test:args("आचार्यनी*")
    %test:assertEquals("cdeva")

function analyze:case-insensitive-wildcard-query($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test1")//tei:p[ft:query(., $querystring)]/@xml:id/string()
};



declare 
    %test:args("khalu")
    %test:assertEquals("bdeva", "biast")
    %test:args("eva")
    %test:assertEquals("cdeva", "ciast")
    %test:args("mutsārya")
    %test:assertEquals("ddeva", "diast")
    %test:args("खलु")
    %test:assertEquals("bdeva", "biast")

function analyze:slp1-simple-term-query($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test3")//tei:p[ft:query(., $querystring)]/@xml:id/string()
};


declare
    %test:args("e?a*")
    %test:assertEquals("adeva", "cdeva", "aiast", "ciast")
    %test:args("pratyu*")
    %test:assertEquals("bdeva", "biast")
function analyze:slp1-wildcard-query-no-diacritics($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test3")//tei:p[ft:query(., $querystring)]/@xml:id/string()
};


declare
    %test:args("kha*")
    %test:assertEquals("bdeva", "biast")
    %test:args("ख*")
    %test:assertEquals("bdeva", "biast")
    %test:args("आचार्यनी*")
    %test:assertEquals("cdeva", "ciast")
    %test:args("ācāryanī*")
    %test:assertEquals("cdeva", "ciast")
function analyze:slp1-wildcard-query-diacritics($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test3")//tei:p[ft:query(., $querystring)]/@xml:id/string()
	(: or with preprocessing? :)
	(: collection("/db/sarit-slp1-tests/test3")//tei:p[ft:query(., app:preprocess-query-string($querystring))]/@xml:id/string() :)
};




declare 
    %test:args("evaṃ AND bahuṣu")
    %test:assertEquals("adeva", "aiast")
    %test:args("eva AND viśodhito")
    %test:assertEquals("cdeva", "ciast")
    %test:args("mutsārya OR (janaḥ AND prayātu)")
    %test:assertEquals("ddeva", "diast")
    %test:args("खलु AND pratyuddhṛteṣu")
    %test:assertEquals("bdeva", "biast")

function analyze:slp1-boolean-query($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test3")//tei:p[ft:query(., $querystring)]/@xml:id/string()
};


declare 
    %test:args("eva* AND bahu*")
    %test:assertEquals("adeva", "aiast")
    %test:args("e?a AND viśodhi*")
    %test:assertEquals("cdeva", "ciast")
    %test:args("muts?ry* OR (ja?aḥ AND pray*)")
    %test:assertEquals("ddeva", "diast")
    %test:args("ख* AND pratyu*")
    %test:assertEquals("bdeva", "biast")

function analyze:slp1-boolean-and-wildcard-query($querystring as xs:string) {
	collection("/db/sarit-slp1-tests/test3")//tei:p[ft:query(., $querystring)]/@xml:id/string()
};
