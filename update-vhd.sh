#!/bin/bash



# base tutorial: 
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8-beta/html-single/deploying_red_hat_enterprise_linux_on_public_cloud_platforms/index#align-image

export DATE=20190219.0
export RELEASE=29
export RAW=/tmp/fedora_atomic_host_$RELEASE_$DATE.raw
export VHD=/tmp/fedora_atomic_host_$RELEASE_$DATE.vhd
export AZ_RESOURCE_GROUP="DefaultResourceGroup-FRC"
export AZ_STORAGE_ACCOUNT="8f5btkybq"
export AZ_CONTAINER="images"
export AZ_REGION="francecentral"
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=8f5btkybq;AccountKey=6NlbHzJ7OBQJrWw/zqbS3b6ZjjWw/vi6axduzkG0MpormL8Sbf4FpEAt3d2P6iRZt7NOkpBOzs+Q7pvBlatX+g=="
export URL=""

align() {
    MB=$((1024 * 1024))
    size=$(qemu-img info -f raw --output json "$1" | gawk 'match($0, /"virtual-size": ([0-9]+),/, val) {print val[1]}')
    rounded_size=$((($size/$MB + 1) * $MB))
    if [ $(($size % $MB)) -eq  0 ]
    then
    echo "Your image is already aligned. You do not need to resize."
    return
    fi
    echo "rounded size = $rounded_size"
    qemu-img resize -f raw $1 $rounded_size
    echo "Your image has been aligned."
}

convert() {
    qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $1 $2
}

upload() {
    az storage blob upload --account-name $AZ_STORAGE_ACCOUNT --container-name $AZ_CONTAINER --type page --file $1 --name $2
    
    export URL=$(az storage blob url -c $AZ_CONTAINER -n $2)
}

create_image() {
    az image create -n $2 -g $AZ_RESOURCE_GROUP -l $AZ_REGION --source $1 --os-type linux
}



run() {
    echo "download raw image $RAW"
    wget https://download.fedoraproject.org/pub/alt/atomic/stable/Fedora-$RELEASE-updates-$DATE/AtomicHost/x86_64/images/Fedora-AtomicHost-$RELEASE-$DATE.x86_64.raw.xz -O $RAW

    echo "align image"
    align $RAW
    
    echo "convert raw to vhd"
    convert $RAW $VHD

    echo "upload to azure"
    upload $VHD $(basename $VHD)

    echo "create azure image"
    create_image $URL "fedora$RELEASE"

}
