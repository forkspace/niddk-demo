#!/bin/sh

SCRIPT_FOLDER=$(dirname $(readlink -f $0))
BASE_FOLDER=$(dirname "$SCRIPT_FOLDER")

customUsage()
{
	cat <<EOM
    	Usage:
	$(basename $0) <user> <pswd> <clusterName>
EOM
        exit 1
}

rawurlencode() 
{
	local data
    if [ $# != 1 ]; then
        echo "Usage: $0 string-to-urlencode"
        return 1
    fi
    data="$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
    if [ $? != 3 ]; then
        echo "Unexpected error" 1>&2
        return 2
    fi
    echo "${data##/?}"
}

#=== FUNCTION ===================================================
#          NAME	: createSolrCluster	
#   DESCRIPTION	: creates a Solr cluster in bluemix
#   PARAMETER 1	: r&r credentials user name
#	PARAMETER 2	: r&r credentials secret
#	PARAMETER 3	: r&r cluster name
#	OUTCOME		: returns the created cluster id, 
#					as in: 
#						clusterId=$(createSolrCluster user pass name)
#================================================================
createSolrCluster() 
{
	local u=$1
	local p=$2
	local n=$3
	result=`curl -H "Content-Type: application/json" -X POST -u "$u":"$p" \\
	-d "{\"cluster_size\":\"1\",\"cluster_name\":\"$n\"}" "$RandR_CLUSTER_URL"`
	echo "$result"
}

checkSolrClusterStatus() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	result=`curl -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId"`
	echo "$result"
}

loadSolrClusterConfig() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local configFile=$4
	result=`curl -X POST -H "Content-Type: application/zip" -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId/config/$RandR_CLUSTER_CONFIG" --data-binary @$configFile`
	echo "$result"
}

createClusterCollection() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local config=$4
	local collection=$5
	result=`curl -X POST -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId/solr/admin/collections" -d "action=CREATE&name=$collection&collection.configName=$config&wt=json"`
	echo "$result"
}

addDocs() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local collection=$4
	local docs=$5

	result=`curl -X POST -H "Content-Type: application/json" -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId/solr/$collection/update"?commit=true --data-binary @$docs`
	echo "$result"
}

exampleQuestion() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local collection=$4
	local question=$(rawurlencode "$5")

	result=`curl -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId/solr/$collection/select?q=$question&wt=json&fl=id,topic,text_description"`
	echo "$result"

}

train() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local collection=$4
	local rankerName=$5
	local trainingFile=$6

	result=`python $BASE_FOLDER/train.py -u $u:$p -i $trainingFile -c $clusterId -x $collection -n $rankerName `
	echo "$result"
}


checkRankerStatus() 
{
	local u=$1
	local p=$2
	local rankerId=$3

	result=`curl -u $u:$p "$RandR_RANKER_URL/$rankerId"`
	echo "$result"
}

rankerQuery() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local collection=$4
	local rankerId=$5
	local question=$(rawurlencode "$6")

	result=`curl -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId/solr/$collection/fcselect?ranker_id=$rankerId&q=$question&wt=json&fl=id,topic,text_description"`
	echo "$result"

}

deleteCluster() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	result=`curl -i -X DELETE -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId"`
	echo "$result"
}

deleteRanker() 
{
	local u=$1
	local p=$2
	local rankerId=$3
	result=`curl -i -X DELETE -u "$u":"$p" "$RandR_RANKER_URL/$rankerId"`
	echo "$result"
}

rankerQuery() 
{
	local u=$1
	local p=$2
	local clusterId=$3
	local collection=$4
	local rankerId=$5
	local question=$(rawurlencode "$6")

	result=`curl -u "$u":"$p" "$RandR_CLUSTER_URL/$clusterId/solr/$collection/fcselect?ranker_id=$rankerId&q=$question&wt=json&fl=id,topic,text_description"`
	echo "$result"

}

trainClassifier() 
{
	local u=$1
	local p=$2
	local trainFile=$3
	local classifierName=$4

	result=`curl -u "$u":"$p" -F training_data=@$trainFile -F training_metadata="{\"language\":\"en\",\"name\":\"$classifierName\"}" "$NLC_URL/classifiers"`
	echo "$result"

}

checkClassifierStatus() 
{
	local u=$1
	local p=$2
	local classifierId=$3
	result=`curl -u "$u":"$p" "$NLC_URL/classifiers/$classifierId"`
	echo "$result"

}

testClassifier()
{

	local u=$1
	local p=$2
	local classifierId=$3
	local question=$(rawurlencode "$4")
	result=`curl -G -u "$u":"$p" "$NLC_URL/classifiers/$classifierId/classify?text=$question"`
	echo "$result"

}

RandR_API_URL="https://gateway.watsonplatform.net/retrieve-and-rank/api"
RandR_CLUSTER_URL="$RandR_API_URL/v1/solr_clusters"
RandR_RANKER_URL="$RandR_API_URL/v1/rankers"
RandR_PSWD=OSgtEG4GOJXw
RandR_USER=fed7ac8c-aa40-4467-9505-94f55fd10972
RandR_CLUSTER_NAME=randr_cluster
RandR_CLUSTER_ID=sc63f91a41_afef_4c03_8996_1d0e3cb18967
RandR_CLUSTER_CONFIG_FILE=../niddk_config.zip
RandR_CLUSTER_CONFIG=niddk_config2
RandR_COLLECTION=niddk_collection2
RandR_DOCS_FILE=solrdocs.json
RandR_RANKER_NAME=niddk_ranker
RandR_RANKER_ID=3b140ax14-rank-3620
RandR_TRAINING_FILE=$BASE_FOLDER/gt_train.csv

NLC_PSWD=7KEZP8t0yIha
NLC_USER=f186b74c-ffd6-4d4b-bc91-ef7851a52137
NLC_URL=https://gateway.watsonplatform.net/natural-language-classifier/api/v1
NLC_URL_TRAINING_FILE=$BASE_FOLDER/nlc_train.csv
NLC_URL_CLASSIFIER_NAME=niddk_classifier
NLC_URL_CLASSIFIER_ID=2374f9x69-nlc-6181


#if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]
#then
#	customUsage
#fi

#clusterId=$(createSolrCluster $RandR_USER $RandR_PSWD $RandR_CLUSTER_NAME)
clusterId=$RandR_CLUSTER_ID
#echo "created cluster id: $clusterId"
clusterStatus=$(checkSolrClusterStatus $RandR_USER $RandR_PSWD $clusterId)
echo "cluster status: $clusterStatus"
#loadSolrClusterConfig $RandR_USER $RandR_PSWD $RandR_CLUSTER_ID $RandR_CLUSTER_CONFIG_FILE
#createClusterCollection $RandR_USER $RandR_PSWD $RandR_CLUSTER_ID $RandR_CLUSTER_CONFIG $RandR_COLLECTION
#addDocs $RandR_USER $RandR_PSWD $RandR_CLUSTER_ID $RandR_COLLECTION $RandR_DOCS_FILE
#exampleQuestion $RandR_USER $RandR_PSWD $RandR_CLUSTER_ID $RandR_COLLECTION "peptic ulcer"
#train $RandR_USER $RandR_PSWD $RandR_CLUSTER_ID $RandR_COLLECTION $RandR_RANKER_NAME $RandR_TRAINING_FILE
#checkRankerStatus $RandR_USER $RandR_PSWD $RandR_RANKER_ID
rankerQuery $RandR_USER $RandR_PSWD $RandR_CLUSTER_ID $RandR_COLLECTION $RandR_RANKER_ID "peptic ulcer"
#trainClassifier $NLC_USER $NLC_PSWD $NLC_URL_TRAINING_FILE $NLC_URL_CLASSIFIER_NAME
#checkClassifierStatus $NLC_USER $NLC_PSWD $NLC_URL_CLASSIFIER_ID
#testClassifier $NLC_USER $NLC_PSWD $NLC_URL_CLASSIFIER_ID "what is peptic ulcer"
