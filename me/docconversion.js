var fs = require('fs');
var watson = require('watson-developer-cloud');


var DocConversion = (function(){

	var document_conversion = null;
	var writeStream = null;
	var count;

	var init = function(filepath){

		document_conversion = watson.document_conversion({
		  username: '2682efff-1725-44dd-b1d6-0e20c3af36ed',
		  password: 'fr8Wq22flRAQ',
		  version: 'v1',
			version_date: '2015-12-01'
		});
		writeStream = fs.createWriteStream(filepath);
		writeStream.on('error', function(err){
			throw err;
		});
		writeStream.write('[');
		count = 0;
	};

	var close = function(){
		console.log('-------CLOSING');
		writeStream.end(']');
	};

	var handleFile = function(filePointer, callback){

		var config = {
		// (JSON) ANSWER_UNITS, NORMALIZED_HTML, or NORMALIZED_TEXT
		file: fs.createReadStream(filePointer),
		conversion_target: document_conversion.conversion_target.ANSWER_UNITS,
		config: {
			    "conversion_target": "ANSWER_UNITS",
			    "answer_units": {
			        "selector_tags": ["h1","h2"]
			    }
			}
		};
		var convCallback = function(cb){
			var cb = cb;
			var f = function(err, response){
				if (err){
		  			console.error(err);
		  			if(cb)
		  				cb(err);
				}
				else 
		      		handleConversion(response, cb);
			}
			return {f: f};
		}(callback);

		// convert a single document
		document_conversion.convert(config, convCallback.f );
	};

	var handleConversion = function(response, callback){

		console.log('Writing a document...');
		var entries = response.answer_units;

		var title = entries[0].title;

		for( var i=0; i<entries.length; i++ ) {
			//entries.forEach(function(value) {
			var value = entries[i];
			var solrDoc = convertAnswerUnit2SolrDoc(value);
			solrDoc = addDocumentFields(solrDoc, title);
			solrDoc = JSON.stringify(solrDoc);
			solrDoc = solrDoc.replace(/\[|\]/g,'');
			solrDoc = solrDoc.replace(/,/g,'\,');
			solrDoc = solrDoc.replace(/—/g,' ');
			if(count++ != 0)
				solrDoc = ',' + solrDoc;
			writeStream.write(solrDoc);
		};

		if(callback)
			callback(null)
	}	
	

	function addDocumentFields(solrDoc, title) {
	  //Add doc title
	  solrDoc.source = title;
	  //Add document feature
	  if(solrDoc.topic.indexOf("causes") > -1 | solrDoc.topic.indexOf("Causes") > -1) {
	    solrDoc.doc_type = 'cause';
	  }
	  else if(solrDoc.topic.indexOf("symptoms") > -1 | solrDoc.topic.indexOf("Symptoms") > -1) {
	    solrDoc.doc_type = 'symptom';
	  }
	  else if(solrDoc.topic.indexOf("complications") > -1 | solrDoc.topic.indexOf("Complications") > -1) {
	    solrDoc.doc_type = 'complications';
	  }
	  else if(solrDoc.topic.indexOf("diagnosed") > -1 | solrDoc.topic.indexOf("Diagnosis") > -1) {
	    solrDoc.doc_type = 'diagnosis';
	  }
	  else if(solrDoc.topic.indexOf("treated") > -1 | solrDoc.topic.indexOf("Treatment") > -1) {
	    solrDoc.doc_type = 'treatment';
	  }
	  else if(solrDoc.topic.indexOf("prevented") > -1) {
	    solrDoc.doc_type = 'prevention';
	  }
		else if(solrDoc.topic.indexOf("What is") > -1 | solrDoc.topic.indexOf("What are") > -1) {
	    solrDoc.doc_type = 'definition';
	  }
	  else {
	    solrDoc.doc_type = 'boilerplate';
	  }
		console.log(solrDoc.source + " " + solrDoc.topic + " " + solrDoc.doc_type);
	  //console.log(solrDoc.topic + " " + solrDoc.doc_type);
	  return solrDoc;
	};

	function convertAnswerUnit2SolrDoc(au) {
		var solrDoc;
		var auContents = au.content;
		auContents.forEach(function(auContent) {
			if (auContent.media_type === 'text/plain') {
				//var cleanText = JSON.stringify(auContent.text);
				//cleanText = cleanText.replace(/\[|\]|;|\"/g,'');
				//console.log(cleanText);
				  solrDoc = {
				    id: au.id,
				    source: '',
				    doc_type: '',
				    topic: au.title,
				    text_description: auContent.text
				  };
			}
		});
		return solrDoc;
	};

	return {
		init: init,
		close: close,
		handleFile: handleFile
	};

})();

module.exports = DocConversion;