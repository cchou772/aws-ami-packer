#!/bin/bash
# this script search for the latest ccpacker image


# Use > 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use > 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to > 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# > 1 ]]
do
key="$1"

case $key in
    -a|--aws_access_key)
    aws_access_key="$2"
    shift # past argument
    ;;
    -as|--aws_secret_key)
    aws_secret_key="$2"
    shift # past argument
    ;;
    -o|--aws_owner_id)
    aws_owner_id="$2"
    shift # past argument
    ;;
    -r|--region)
    region="$2"
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done


if [ -z "${aws_access_key}" ]; then
     echo "argument -a or --aws_access_key is required."
     parameter_error=true
fi
if [ -z "${aws_secret_key}" ]; then
     echo "argument -as or --aws_secret_key is required."
     parameter_error=true
fi
if [ -z "${aws_owner_id}" ]; then
     echo "argument -o or --aws_owner_id is required."
     parameter_error=true
fi
if [ -z "${region}" ]; then
     echo "argument -d or --region is required."
     parameter_error=true
fi

if [[ "${parameter_error}" ]]; then
  exit 1
fi

echo aws_owner_id  = "${aws_owner_id}"
echo aws_access_key  = "${aws_access_key}"
echo aws_secret_key  = "${aws_secret_key}"
echo region  = "${region}"

#get AWS lastest image id and name
echo "start searching ......."
results=(`python src/python/get-ccpacker-base-images.py -o ${aws_owner_id} -k ${aws_access_key} -s ${aws_secret_key} -r ${region}`)

if [ ${#results[@]} -eq 0 ]; then
    echo "no ccpacker image found!!!!"
else
AMI_ID=${results[0]}
AMI_NAME=${results[1]}

echo "---- Got ccpacker latest image at ----"
echo "ccpacker AMI_ID="$AMI_ID
echo "ccpacker AMI_NAME="$AMI_NAME
fi