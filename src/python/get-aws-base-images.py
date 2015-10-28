##
## this script requires 3 parameters:
## aws_access_key, aws_secret_key, region
## it will return the latest AWS hvm+x86_64+ebs AMI id and name
##
__author__ = 'chien-liang chou'

import boto3
from boto3.session import Session
import json
import datetime
import sys
import getopt

class JSONEncoder(json.JSONEncoder):
    def default(self, o):

            return {
                "VirtualizationType": o.virtualization_type,
                "Name": o.name,
                "Platform" : o.platform,
                "Hypervisor":o.hypervisor,
                "OwnerAlias": o.image_owner_alias,
                "SriovNetSupport": o.sriov_net_support,
                "ImageId": o.id,
                "State": o.state,
                "BlockDeviceMappings": "to be implemented",
                "Architecture": o.architecture,
                "ImageLocation": o.image_location,
                "RootDeviceType": o.root_device_type,
                "OwnerId":o.owner_id,
                "RootDeviceName": o.root_device_name,
                "CreationDate": o.creation_date,
                "Public": o.public,
                "ImageType": o.image_type,
                "Description": o.description
            }


# get aws_key, aws_secret, and region arguments
def getargs(argv):
    aws_key = ""
    aws_secret = ""
    region =""
    try:
        opts, args = getopt.getopt(argv,"k:s:r:",["aws_key=","aws_secret=", "region="])
    except getopt.GetoptError:
        print 'get-aws-base-images.py -k <aws_key> -s <aws_secret> -r <region>'
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-k", "--aws_key"):
            aws_key = arg
        elif opt in ("-s", "--aws_secret"):
            aws_secret = arg
        elif opt in ("-r", "--region"):
            region = arg
    return [aws_key, aws_secret, region]


def getImageCreationDate(image):
    return image.creation_date

def imageFilter(image, datetimeFilter):
    return (image.platform is None) and ("gp2" in image.name) and ("rc" not in image.name) and (datetime.datetime.strptime(image.creation_date, "%Y-%m-%dT%H:%M:%S.%fZ")>datetimeFilter)

def getAwsAmi(aws_key, aws_secret, region):
    if aws_key == '':
        session = Session(region_name=region)
    else:
        session = Session(region_name=region, aws_access_key_id=aws_key, aws_secret_access_key=aws_secret)

    ec2 = session.resource('ec2')
    image_list = ec2.images.filter(Owners=['amazon'],
                                   Filters
                                   = [ {'Name': 'virtualization-type',
                                        'Values': ['hvm']},
                                       {'Name': 'architecture',
                                        'Values': ['x86_64']},
                                       {'Name': 'root-device-type',
                                        'Values': ['ebs']},
                                      ]
                                   )

    threeMonthAgo = datetime.datetime.today() - datetime.timedelta(3*365/12)
    image_list = [m for m in image_list if imageFilter(m, threeMonthAgo)]
    image_list = sorted(image_list, key= getImageCreationDate, reverse= True)

    #for image in image_list:
    #    print json.dumps(image, cls=JSONEncoder)

    #get standard image
    image_list = [m for m in image_list if ("-nat-" not in m.name)]
    return image_list[0]



##
## this script requires 3 parameters:
## aws_access_key, aws_secret_key, region
##
args=getargs(sys.argv[1:])
image=getAwsAmi(args[0], args[1], args[2])
sys.stdout.write(image.id)
sys.stdout.write(" ")
sys.stdout.write(image.name)
sys.stdout.write("\n")

exit(0)
