# Find new disk in /dev or with dmesg
# Using /dev/sdb as example
fdisk /dev/sdb
# In fdisk command menu now
# To create a new partition type the following character
n
# Select primary
p
# Select partition number
1
# Select starting point for the partition
[Enter] # Will use default
# Select end point for the partition
[Enter] # Will use default
# Run the following to preview the partition table as it stands
p
# Run the following to write partition to disk and exit fdisk menu
w
# Run the following to reload kernel so it knows the new partition exists
partprobe
# Run the following to format the drive as xfs
mkfs.xfs /dev/sdb1 # Using sdb1 instead of sdb because you want the partition not the device
# Add a label to the drive
xfs_admin -L /var/data /dev/sdb1 # /var/data being the place we plan to mount it
# Create mount point directory
mkdir /var/data
# Mount new drive to newly created directory
mount -t xfs /dev/sdb1 /var/data