#!/bin/bash
# this script takes the latest AWS hvm+x86_64+ebs AMI,
#             installs newrelic,
#             installs sumologic,
#             changes timezone to new york,
# and then create a new ccpacker ami.


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
    -s|--sumo_access_id)
    sumo_access_id="$2"
    shift # past argument
    ;;
    -sk|--sumo_access_key)
    sumo_access_key="$2"
    shift # past argument
    ;;
    -n|--newrelic_key)
    newrelic_key="$2"
    shift # past argument
    ;;
    -d|--disksize)
    disksize="$2"
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
if [ -z "${sumo_access_id}" ]; then
     echo "argument -s or --sumo_access_id is required."
     parameter_error=true
fi
if [ -z "${sumo_access_key}" ]; then
     echo "argument -sk or --sumo_access_key is required."
     parameter_error=true
fi
if [ -z "${newrelic_key}" ]; then
     echo "argument -n or --newrelic_key is required."
     parameter_error=true
fi
if [ -z "${disksize}" ]; then
     echo "argument -d or --disksize is required."
     parameter_error=true
fi
if [ -z "${region}" ]; then
     echo "argument -d or --region is required."
     parameter_error=true
fi

if [[ "${parameter_error}" ]]; then
  exit 1
fi

echo aws_access_key  = "${aws_access_key}"
echo aws_secret_key  = "${aws_secret_key}"
echo sumo_access_id  = "${sumo_access_id}"
echo sumo_access_key  = "${sumo_access_key}"
echo newrelic_key  = "${newrelic_key}"
echo disksize  = "${disksize}"
echo region  = "${region}"

#get AWS lastest image id and name
echo "start searching ......."
results=(`python src/python/get-aws-base-images.py -k ${aws_access_key} -s ${aws_secret_key} -r ${region}`)

AMI_ID=${results[0]}
AMI_NAME=${results[1]}

echo "---- Got Amazon latest image at ----"
echo "AMI_ID="$AMI_ID
echo "AMI_NAME="$AMI_NAME


./packer_0.8.6/packer build  -var "aws_access_key=${aws_access_key}" \
                             -var "aws_secret_key=${aws_secret_key}" \
                             -var "sumo_access_id=${sumo_access_id}" \
                             -var "sumo_access_key=${sumo_access_key}" \
                             -var "newrelic_key=${newrelic_key}" \
                             -var "size=${disksize}" \
                             -var "region=${region}" \
                             -var "source_ami=$AMI_ID" \
                             -var "source_ami_name=$AMI_NAME" \
                             src/packer/ccpacker-ami.json
