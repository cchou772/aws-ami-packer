# ami-manager

## To create a new image basing on the latest AWS image:

create-cc-ami.sh -a  <aws_access_key>
                 -as <aws_secret_key>
                 -s  <sumo_access_id>
                 -sk <sumo_access_key>
                 -n  <newrelic_key>
                 -d  <disksize>
                 -r  <region>

## To get the image id created by create-cc-ami.sh
get-cc-ami.sh -a  <aws_access_key>
              -as <aws_secret_key>
              -o  <aws_owner_id>
              -r  <region>