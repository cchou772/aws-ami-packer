__author__ = 'chien-liang chou'


from boto3.session import Session
import sys
import getopt



# get aws_key and aws_secret arguments
def getargs(argv):
    aws_owner_id =""
    aws_key = ""
    aws_secret = ""
    region = ""
    try:
        opts, args = getopt.getopt(argv,"o:k:s:r:",["aws_owner_id","aws_key=","aws_secret=", "regions="])
    except getopt.GetoptError:
        print 'get-ccpacker-base-images.py -o <aws_owner_id> -k <aws_key> -s <aws_secret> -r <region>'
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-k", "--aws_key"):
            aws_key = arg
        elif opt in ("-o", "--owner_id"):
            aws_owner_id = arg
        elif opt in ("-s", "--aws_secret"):
            aws_secret = arg
        elif opt in ("-r", "--region"):
            region = arg
    return [aws_owner_id, aws_key, aws_secret, region]


def getImageCreationDate(image):
    return image.creation_date

#filter image name by ccpacker-
def imageFilter(image):
    return ("ccpacker-" in image.name)


def get_cc_ami(aws_owner_id, aws_key, aws_secret, region):
    if aws_key == '':
        session = Session(region_name=region)
    else:
        session = Session(region_name=region, aws_access_key_id=aws_key, aws_secret_access_key=aws_secret)

    ec2 = session.resource('ec2')
    image_list = ec2.images.filter(Owners=[aws_owner_id])
    image_list = [m for m in image_list if imageFilter(m)]
    image_list = sorted(image_list, key= getImageCreationDate, reverse= True)

    if len(image_list)>0:
        sys.stdout.write(image_list[0].id)
        sys.stdout.write(" ")
        sys.stdout.write(image_list[0].name)
        sys.stdout.write("\n")


args=getargs(sys.argv[1:])
get_cc_ami(args[0], args[1], args[2], args[3])

exit(0)
