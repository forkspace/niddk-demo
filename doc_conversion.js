var fs = require('fs');
var watson = require('watson-developer-cloud');
var cli = require('cli');

var options = cli.parse({
	dir: [ 'i', 'directory to process', 'dir', null]
});

cli.main(function(args,options) {
	if(options.dir == null) {
		cli.getUsage();
		exit();
	}
});

var document_conversion = watson.document_conversion({
  username: '2682efff-1725-44dd-b1d6-0e20c3af36ed',
  password: 'fr8Wq22flRAQ',
  version: 'v1',
	version_date: '2015-12-01'
});

var entriesCount = 0;
var inputDirectory = __dirname + '/' + options.dir;


var walk = function(directory, done) {
  var results = [];
  fs.readdir(directory, function(err, list) {
    if (err) return done(err);
    var i = 0;
    (function next() {
      var file = list[i++];
      if (!file) return done(null, results);
      file = directory + '/' + file;
      fs.stat(file, function(err, stat) {
        if (stat && stat.isDirectory()) {
          walk(file, function(err, res) {
            results = results.concat(res);
            next();
          });
        } else {
          convert(file);
          next();
        }
      });
    })();
  });
};''

fs.unlink('solrdocs.json', function(err){
        if(err)
          console.error(err);
        else
           fs.appendFile('solrdocs.json', '[', function(err) {
              if(err)
                return console.log(err);
              else {
                walk(inputDirectory, function(err, results) {
                  if (err) 
                    throw err;
                  console.log(results);
                });
              }

            }); 
});




function convert(file) {
  // convert a single document
  document_conversion.convert({
    // (JSON) ANSWER_UNITS, NORMALIZED_HTML, or NORMALIZED_TEXT
    file: fs.createReadStream(file),
    conversion_target: document_conversion.conversion_target.ANSWER_UNITS,
    config: {
		    "conversion_target": "ANSWER_UNITS",
		    "answer_units": {
		        "selector_tags": ["h1","h2"]
		    }
		}
  }, function(err, response) {
    if (err) {
      console.error(err);
    } else {
          writeLocal(response);
    }
  });
}

var solrDocWriter = function(){
  
  var entriesCounter = 0;
  
  var write = function(){

  };

  var close = function(){


  };

  var return{ write: write, close: close};
};

function writeLocal(data) {

  console.log('Writing a document...');
  var answerUnits = data.answer_units;
  //var solrWrapper = [];
  var title = answerUnits[0].title;

  if(0 == entriesCount){
    fs.appendFile('solrdocs.json', '[', function(err) {
      if(err)
        return console.log(err);
    });
  }
  

  for( var i=0; i<answerUnits.length; i++ ) {
  //answerUnits.forEach(function(value) {
    var value = answerUnits[i];
    var solrDoc = convertAnswerUnit2SolrDoc(value);
    solrDoc = addDocumentFields(solrDoc, title);
		solrDoc = JSON.stringify(solrDoc);
		solrDoc = solrDoc.replace(/\[|\]/g,'');
		solrDoc = solrDoc.replace(/,/g,'\,');
		solrDoc = solrDoc.replace(/—/g,' ');
    //console.log(solrDoc);
    //solrWrapper.push(solrDoc);
		//console.log(solrWrapper);
		//var docContents = ',' + JSON.stringify(solrWrapper);
    fs.appendFile('solrdocs.json', (i > 0 ? ',' + solrDoc : solrDoc) , function(err) {
      if(err) 
        return console.log(err);
      
    });
  };
  fs.appendFile('solrdocs.json', ']', function(err) {
      if(err)
        return console.log(err);
  });
	return;
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
  return(solrDoc);
};
