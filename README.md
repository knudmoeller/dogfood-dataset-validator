DOGFOOD DATASET VALIDATOR
=========================

Knud Möller

Ruby code to run a series of SPARQL queries over an RDF dataset of a conference or workshop event. The queries are (more or less) identical to those that produce the output on http://data.semanticweb.org, and in this way validate if the dataset contains the correct data to be displayed.

* a single dataset can be validated using the validate.rb script
* running the script requires that a Fuseki server (http://jena.apache.org/documentation/serving_data/) is running on http://localhost:3030 (the default Fuseki setup)
* the script is run like this:

``` 
ruby validate.rb PATH/TO/DATASET.ttl "http://URI/OF/DATASET/GRAPH"
``` 

* the dataset graph URI must be the one linked from the event URI with `swc:completeGraph`
* the script works by first running an **entity query** to get the URIs of one or more entities for which HTML display should be simulated
* the entity query is passed several **view queries**, which get the necessary data for creating the HTML display
* some view queries are required, some are not
* the scripts outputs log statements to STDERR
* if an optional view query doesn't get any results, a WARN log statement is generated
* if a required view query doesn't get any results, an ERROR log statement is generated
* a WARN or ERROR statement will contain the path to the query and the URI of the current entity. This information can be used for debugging the dataset.

Problems
========

* the queries currently aren't completely identical to the ones used on the site. This is because the site uses a Sesame RDF store (for historical reasons), and the validator uses Jena/Fuseki (because it's easier to script and handle from the command line)
* Sesame and Jena seem to have a slightly different interpretation of named graphs: In Sesame, a query with no `GRAPH` clause will match patterns in *any* graph in the triple store, i.e., the default graph and any named graph. On the other hand, a query with no `GRAPH` clause in Jena will only match patterns in the default graph.
* I'm not sure who is right, but this leads to some incompatibilities

