#!/bin/bash
######Setting variables#######
#set data
historydata=$( date -d "yesterday 13:00 " '+%Y-%m-%d' )
data=`date +%Y-%m-%d`
#set full data
fulldate=`date +%d-%m-%Y-%T`
#set node list filename. node_list with full set of ip addressses or list_tmp for testing with 1-2 addresses
list="node_list"
#list="list_tmp"
#set working folder path
wf="/path/to/working/folder"
#git repo
gitdir="$wf/git-folder-name"
#set backip folder
bf="$wf/rsc"
#set logs folder
logs="$wf/logs"
#Telegram Bot Api
tba="bot12345:AAABBB"
#Telegram ChatID
tci="123456789"
keyfile="/path/to/privatekey/file" #path to private key file
username="admin" #username for connection
client="ClientName" #Client name

#Some functions

GeneralLogs(){
    fulldate=`date +%d-%m-%Y-%T`
    
    if [ $? -eq 0 ]; then
        echo "$fulldate OK" | tee -a $wf/logs/$data.log
    else
        echo "$fulldate Error $?" | tee -a $wf/logs/$data.log
    fi
}

NodeLogs(){
    fulldate=`date +%d-%m-%Y-%T`
    if [ $? -eq 0 ]; then
        echo "$fulldate OK" | tee -a $bf/$folder/log/$data.log
    else
        echo "$fulldate Error $?" | tee -a $bf/$folder/log/$data.log
    fi
    
}

#########################Stop Editing####################
echo "$fulldate Creating folder "logs""

mkdir -p $logs
GeneralLogs

while read node
do
    
    echo "$fulldate ====================Starting new backup of node $node =================="  | tee -a $wf/logs/$data.log
    #set up identity
    
    #get identity from RoS
    echo "$fulldate Getting identity from RoS... ssh -n -i $keyfile $rspub@$node /system identity print" | tee -a $wf/logs/$data.log
    nodename=$(ssh -n -i $keyfile $username@$node /system identity print)
    if [ $? -eq 0 ]; then
        echo "$fulldate OK" | tee -a $wf/logs/$data.log | tee -a $wf/logs/$data.log
    else
        echo -e "$fulldate \e[1;31m Error $? \e[0m" | tee -a $wf/logs/$data.log
        
        echo -e "$fulldate \e[1;31m Couldn't connect to $node \e[0m" | tee -a $wf/logs/$data.log
        
        echo -e "$fulldate \e[1;31m Scipping $node \e[0m" | tee -a $wf/logs/$data.log
        continue
    fi
    echo "$nodename" | tee -a $wf/logs/$data.log
    
    #Removing unwanted letters
    echo "$fulldate Removing unwanted letters..." | tee -a $wf/logs/$data.log
    
    #Removing "name:   "
    identity="${nodename//  name: /}"
    GeneralLogs
    
    #Removing carriage returns (Last 3 symbol)
    echo "$fulldate Removing carriage returns"  | tee -a $wf/logs/$data.log
    identity=${identity%???}
    GeneralLogs
    
    #Adding .rsc extension
    echo "$fulldate Adding .rsc extension"  | tee -a $wf/logs/$data.log
    filename="$identity.rsc"
    GeneralLogs
    
    #Setting up folders name
    echo "$fulldate Setting up folders name" | tee -a $wf/logs/$data.log
    folder="$identity"
    GeneralLogs
    
    echo "$fulldate Creating folder "log"" | tee -a $wf/logs/$data.log
    mkdir -p $bf/$folder/log
    GeneralLogs
    
    #Create log folder for git
    
    mkdir -p $gitdir/$folder/log | tee -a $wf/logs/$data.log
    GeneralLogs
    
    echo "$fulldate Starting backup of $identity. You can see log in $bf/$folder/log/$data.log"
    echo $fulldate Backing up $identity  $node...  | tee -a $bf/$folder/log/$data.log
    
    
    #connect to RoS and create backup file
    echo "$fulldate Connecting to $node..." | tee -a $bf/$folder/log/$data.log
    ssh -i $keyfile -n $username@$node export file=[/system identity get name]
    NodeLogs
    
    #creating folders curr and history if doesn't exist!!!!!!!!!!!!!!!!!
    echo "$fulldate Creating folder "curr""  | tee -a $wf/logs/$data.log
    mkdir -p $bf/$folder/curr
    GeneralLogs
    echo "$fulldate Creating folder "history"" | tee -a $wf/logs/$data.log
    mkdir -p $bf/$folder/history
    
    GeneralLogs
    
    #move old backup to the history folder
    echo "$fulldate Moving old backup $filename to the history folder" | tee -a $bf/$folder/log/$data.log
    mv -v -f $bf/$folder/curr/$filename $bf/$folder/history/$folder.$historydata.rsc >> $bf/$folder/log/$data.log 2>> $bf/$folder/log/$data.error.log
    NodeLogs
    #cd to folder
    echo "$fulldate cd to $bf/$folder/curr" | tee -a $bf/$folder/log/$data.log
    cd $bf/$folder/curr
    NodeLogs
    
    #connecting to RoS by sftp and fetch backup file
    echo "$fulldate Fetching $filename from $node" | tee -a $bf/$folder/log/$data.log
    sftp -i $keyfile $username@$node:*$filename
    NodeLogs
    
    #copy rsc file to git dir
    echo "$fulldate Copying file to git dir using cp -i $bf/$folder/curr/*.rsc $gitdir/$folder" | tee -a $bf/$folder/log/$data.log
    cp $bf/$folder/curr/*.rsc $gitdir/$folder
    NodeLogs
    
    #connect to RoS and remove old file
    echo "$fulldate Removing $filename from $node" | tee -a  $bf/$folder/log/$data.log
    ssh -n -i $keyfile $username@$node /file remove [find where name="$filename"]
    NodeLogs
    
done < "$wf/$list"
echo "$fulldate Backup finished" | tee -a $wf/logs/$data.log


#Checking for errors

echo  "$fulldate ------------------------------"
echo "$fulldate Checking for nodes errors"
cd $bf

for dir in $bf/* ; do
    
    #Get dir name
    dirname="${dir##*/}"
    
    #Checking if fresh log file exist
    echo "$fulldate ========ErrCheck==== Working with $dirname====" | tee -a $wf/logs/$data-check.log
    if [ -f "$dir/log/$data.error.log" ]
    then
        if [ -s "$dir/log/$data.error.log" ]
        then
            echo "$fulldate File exists and not empty. Check log data." | tee -a $wf/logs/$data-check.log
            #Send message to telegram
            curl "https://api.telegram.org/$tba/sendMessage?chat_id=$tci&text=$client $dirname log has error: $logfile"
            curl -F document=@$dir/log/$data.error.log caption=@test1 https://api.telegram.org/$tba/sendDocument?chat_id=$tci?caption=test2
        else
            
            #write that all OK
            echo "$fulldate OK ($dir/log/$data.error.log)" | tee -a $wf/logs/$data-check.log
        fi
    else
        
        #If file doesn't exist, backup failed, write to log file
        echo "$fulldate File does not exists" | tee -a $wf/logs/$data-check.log
        
        #and send to telegram
        curl "https://api.telegram.org/$tba/sendMessage?chat_id=$tci&text=$client $dirname backup failed"
    fi
    
    echo "$fulldate ========ErrCheck====Finished====" | tee -a $wf/logs/$data-check.log
done

echo  "$fulldate ------------------------------" | tee -a $wf/logs/$data-check.log
echo "$fulldate Checking complete for node" | tee -a $wf/logs/$data-check.log

#Removing creating date from *.rsc file

echo  "$fulldate ------------------------------" | tee -a $wf/logs/$data-check.log
echo "$fulldate Removing date from RSC file" | tee -a $wf/logs/$data-check.log
cd $gitdir
for dir in $gitdir/* ; do
    
    #Get dir name. Cut all before last slash
    dirname="${dir##*/}"
    
    echo "$fulldate ============Working with $dirname====" | tee -a $wf/logs/$data.log
    
    #Remove all from first line with "by RouterOS" and replace with "#"
    sed -i '1s/^.*by RouterOS/#/' $dirname/*.rsc
    
    #check_for_errors
    echo "$fulldate ===Finished with $dirname===" | tee -a $wf/logs/$data.log
done

echo  "$fulldate ------------------------------" | tee -a $wf/logs/$data.log
echo "$fulldate Finished removing date from RSC file" | tee -a $wf/logs/$data.log


echo "$fulldate --------------------" | tee -a $wf/logs/$data.log
echo "$fulldate Checking general log for errors" | tee -a $wf/logs/$data-check.log


cat $wf/logs/$data.log | grep Error
if [ $? -eq 0 ]; then
    echo "$fulldate Error" | tee -a $wf/logs/$data-check.log
    curl "https://api.telegram.org/$tba/sendMessage?chat_id=$tci&text=$client Found error in $wf/logs/$data.log. Please check it manually"
    
else
    echo "$fulldate OK" | tee -a $wf/logs/$data-check.log
fi
echo "--------------------" | tee -a $wf/logs/$data-check.log
echo "$fulldate Checking general log for error complete" | tee -a $wf/logs/$data-check.log


###### git ######
echo "$fulldate ==========G I T==========" | tee -a $wf/logs/$data.log
#cd to folder
echo "$fulldate cd to $gitdir" | tee -a $wf/logs/$data.log
cd $gitdir
GeneralLogs

echo "$fulldate git pull --all" | tee -a $wf/logs/$data.log
git pull --all | tee -a $wf/logs/$data.log

GeneralLogs

#git add
echo "$fulldate git add ." | tee -a $wf/logs/$data.log
git add . | tee -a $wf/logs/$data.log
GeneralLogs

#git commit
echo "$fulldate git commit" | tee -a $wf/logs/$data.log
git commit -m "Uploaded $fulldate" | tee -a $wf/logs/$data.log
GeneralLogs

#git push to repo
echo "$fulldate git push" | tee -a $wf/logs/$data.log
git push -u origin master | tee -a $wf/logs/$data.log
GeneralLogs

echo "$fulldate --------------------" | tee -a $wf/logs/$data.log
echo "$fulldate GIT comlete" | tee -a $wf/logs/$data-check.log

echo " $fulldate TASK FINISHED" | tee -a $wf/logs/$data.log
