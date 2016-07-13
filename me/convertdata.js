var fs = require('fs');
var watson = require('watson-developer-cloud');
var cli = require('cli');
var conversion = require('./docconversion');
var outputFile = 'solrdocs.json';


var options = cli.parse({
	dir: [ 'i', 'directory to process', 'dir', null]
});

cli.main(function(args,options) {
	if(options.dir == null) {
		cli.getUsage();
		exit();
	}
});

conversion.init(outputFile);

var inputDirectory = __dirname + '/' + options.dir;

fs.readdir(inputDirectory, 
  function(err, list) {
    if (err) 
      throw err;

    list.forEach(function(currentValue, index, array){

      var closeCb = function(o){
        var conv = o;

        var cb = function(){
          setTimeout(conv.close, 4000);
        };

        return {cb: cb};
      }(conversion);

      var file = inputDirectory + '/' + currentValue;
      fs.stat(file, function(err, stat) {
        if(err)
          throw err;
        
        if(stat && stat.isFile()){
          console.log('index:%d arraylength:%d', index, array.length);
          if(index == array.length - 1)
            conversion.handleFile(file, closeCb.cb);
          else
            conversion.handleFile(file);
        }

      });

    });
  }
);

